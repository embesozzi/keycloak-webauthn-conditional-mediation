<#import "template.ftl" as layout>
    <@layout.registrationLayout; section>
    <#if section = "title">
     title
    <#elseif section = "header">
        ${kcSanitize(msg("webauthn-login-title"))?no_esc}
    <#elseif section = "form">
        <form id="webauth" action="${url.loginAction}" method="post">
            <input type="hidden" id="clientDataJSON" name="clientDataJSON"/>
            <input type="hidden" id="authenticatorData" name="authenticatorData"/>
            <input type="hidden" id="signature" name="signature"/>
            <input type="hidden" id="credentialId" name="credentialId"/>
            <input type="hidden" id="userHandle" name="userHandle"/>
            <input type="hidden" id="error" name="error"/>
        </form>
        <div class="${properties.kcFormGroupClass!} no-bottom-margin">
            <#if authenticators??>
                <form id="authn_select" class="${properties.kcFormClass!}">
                    <#list authenticators.authenticators as authenticator>
                        <input type="hidden" name="authn_use_chk" value="${authenticator.credentialId}"/>
                    </#list>
                </form>

                <#if shouldDisplayAuthenticators?? && shouldDisplayAuthenticators>
                    <#if authenticators.authenticators?size gt 1>
                        <p class="${properties.kcSelectAuthListItemTitle!}">${kcSanitize(msg("webauthn-available-authenticators"))?no_esc}</p>
                    </#if>

                    <div class="${properties.kcFormClass!}">
                        <#list authenticators.authenticators as authenticator>
                            <div id="kc-webauthn-authenticator" class="${properties.kcSelectAuthListItemClass!}">
                                <div class="${properties.kcSelectAuthListItemIconClass!}">
                                    <i class="${(properties['${authenticator.transports.iconClass}'])!'${properties.kcWebAuthnDefaultIcon!}'} ${properties.kcSelectAuthListItemIconPropertyClass!}"></i>
                                </div>
                                <div class="${properties.kcSelectAuthListItemBodyClass!}">
                                    <div id="kc-webauthn-authenticator-label"
                                            class="${properties.kcSelectAuthListItemHeadingClass!}">
                                        ${kcSanitize(msg('${authenticator.label}'))?no_esc}
                                    </div>

                                    <#if authenticator.transports?? && authenticator.transports.displayNameProperties?has_content>
                                        <div id="kc-webauthn-authenticator-transport"
                                                class="${properties.kcSelectAuthListItemDescriptionClass!}">
                                            <#list authenticator.transports.displayNameProperties as nameProperty>
                                                <span>${kcSanitize(msg('${nameProperty!}'))?no_esc}</span>
                                                <#if nameProperty?has_next>
                                                    <span>, </span>
                                                </#if>
                                            </#list>
                                        </div>
                                    </#if>

                                    <div class="${properties.kcSelectAuthListItemDescriptionClass!}">
                                        <span id="kc-webauthn-authenticator-created-label">
                                            ${kcSanitize(msg('webauthn-createdAt-label'))?no_esc}
                                        </span>
                                        <span id="kc-webauthn-authenticator-created">
                                            ${kcSanitize(authenticator.createdAt)?no_esc}
                                        </span>
                                    </div>
                                </div>
                                <div class="${properties.kcSelectAuthListItemFillClass!}"></div>
                            </div>
                        </#list>
                    </div>
                </#if>
            </#if>
                <div id="kc-form">
                <div id="kc-form-wrapper">
                    <#if realm.password>
                        <form id="kc-form-login" style="display:none" onsubmit="login.disabled = true; return true;" action="${url.loginAction}" method="post">
                            <#if !usernameHidden??>
                                <div class="${properties.kcFormGroupClass!}">
                                    <label for="username"
                                        class="${properties.kcLabelClass!}"><#if !realm.loginWithEmailAllowed>${msg("username")}<#elseif !realm.registrationEmailAsUsername>${msg("usernameOrEmail")}<#else>${msg("email")}</#if></label>

                                    <input tabindex="1" id="username"
                                        aria-invalid="<#if messagesPerField.existsError('username')>true</#if>"
                                        class="${properties.kcInputClass!}" name="username"
                                        value="${(login.username!'')}"
                                        autocomplete="username webauthn"
                                        type="text" autofocus autocomplete="off"/>

                                    <#if messagesPerField.existsError('username')>
                                        <span id="input-error-username" class="${properties.kcInputErrorMessageClass!}" aria-live="polite">
                                            ${kcSanitize(messagesPerField.get('username'))?no_esc}
                                        </span>
                                    </#if>
                                </div>
                            </#if>
                            <div id="kc-form-buttons" class="${properties.kcFormGroupClass!}">
                                <input tabindex="4"
                                    class="${properties.kcButtonClass!} ${properties.kcButtonPrimaryClass!} ${properties.kcButtonBlockClass!} ${properties.kcButtonLargeClass!}"
                                    name="login" id="kc-login" type="submit" value="${msg("doLogIn")}"/>
                            </div>
                        </form>
                    </#if>
                </div>
                <div id="kc-form-buttons-webauthn" style="display:none" >
                    <hr>
                    <input id="authenticateWebAuthnButton" type="button" onclick="webAuthnAuthenticate()" autofocus="autofocus"
                        value="${kcSanitize(msg("webauthn-doAuthenticate"))}"
                        class="${properties.kcButtonClass!} ${properties.kcButtonPrimaryClass!} ${properties.kcButtonBlockClass!} ${properties.kcButtonLargeClass!}"/>
                </div>
            </div>
        </div>
    <script type="text/javascript" src="${url.resourcesCommonPath}/node_modules/jquery/dist/jquery.min.js"></script>
    <script type="text/javascript" src="${url.resourcesPath}/js/base64url.js"></script>
    <script type="text/javascript">
        const authnOptions = {
            challenge : "${challenge}",
            userVerification : "${userVerification}",
            rpId : "${rpId}",
            createTimeout : ${createTimeout},
            isUserIdentified: ${isUserIdentified},
            userVerification: "${userVerification}"
        }

        window.onload = () => {
            if(!authnOptions.isUserIdentified) {
                document.getElementById("kc-form-login").style.display = "block";
            }
            showWebAuthnLogin(); 
        }

        const showWebAuthnLogin  = async() => {
            if (window.PublicKeyCredential) {
                let isConditionalMediationAvailable;
                if(PublicKeyCredential.isConditionalMediationAvailable) {
                    isConditionalMediationAvailable = await PublicKeyCredential.isConditionalMediationAvailable();
                }
                if(!authnOptions.isUserIdentified && isConditionalMediationAvailable) {
                    webAuthnAuthenticate({ mediation: 'conditional'});
                }
                else {
                    document.getElementById("kc-form-buttons-webauthn").style.display = 'block';
                }
            }
        }    

        const getAllowCredentials = () => {
            let allowCredentials = [];
            let authn_use = document.forms['authn_select'].authn_use_chk;
            if (authn_use !== undefined) {                
                if (authn_use.length === undefined) {
                    allowCredentials.push({
                        id: base64url.decode(authn_use.value, {loose: true}),
                        type: 'public-key',
                    });
                } else {
                    for (let i = 0; i < authn_use.length; i++) {
                        allowCredentials.push({
                            id: base64url.decode(authn_use[i].value, {loose: true}),
                            type: 'public-key',
                        });
                    }
                }
            }
            return allowCredentials;
        }

        const getPublicKeyRequestOptions = () => {
            let publicKeyReqOptions = {};
            publicKeyReqOptions.rpId = authnOptions.rpId;
            publicKeyReqOptions.challenge = base64url.decode(authnOptions.challenge, { loose: true });
            publicKeyReqOptions.allowCredentials = !authnOptions.isUserIdentified ? [] : getAllowCredentials();

            if(authnOptions.createTimeout !== 0) publicKeyReqOptions.timeout = authnOptions.createTimeout * 1000;
            if (authnOptions.userVerification !== 'not specified') publicKeyReqOptions.userVerification = authnOptions.userVerification; 
            
            return publicKeyReqOptions;
        }

        const webAuthnAuthenticate = async (mediationOptions) => {
            
            const credential = await navigator.credentials.get({
                publicKey: getPublicKeyRequestOptions(),
                ...mediationOptions
            }).catch(handleWebAuthError);

            window.result = credential;

            $("#clientDataJSON").val(encondeBase64AsUint8Array(result.response.clientDataJSON));
            $("#authenticatorData").val(encondeBase64AsUint8Array(result.response.authenticatorData));
            $("#signature").val(encondeBase64AsUint8Array(result.response.signature));
            $("#credentialId").val(result.id);
            if(result.response.userHandle) {
                $("#userHandle").val(encondeBase64AsUint8Array(result.response.userHandle));
            }
            $("#webauth").submit();
        }

        const handleWebAuthError = (e) => {
            if (e.name !== 'NotAllowedError') {
                console.error(error);
            }
            $("#error").val(e);
            $("#webauth").submit();
        }

        const encondeBase64AsUint8Array = (value) => {
            return base64url.encode(new Uint8Array(value), { pad: false });
        }

    </script>
    <#elseif section = "info">

    </#if>
    </@layout.registrationLayout>