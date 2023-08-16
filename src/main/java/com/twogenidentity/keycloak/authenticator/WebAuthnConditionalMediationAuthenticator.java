package com.twogenidentity.keycloak.authenticator;

import org.jboss.logging.Logger;
import org.keycloak.authentication.AuthenticationFlowContext;
import org.keycloak.authentication.authenticators.browser.UsernameForm;
import org.keycloak.authentication.authenticators.browser.WebAuthnPasswordlessAuthenticator;
import org.keycloak.models.KeycloakSession;
import org.keycloak.services.managers.AuthenticationManager;
import org.keycloak.utils.StringUtil;

import javax.ws.rs.core.MultivaluedMap;
import javax.ws.rs.core.Response;

public class WebAuthnConditionalMediationAuthenticator extends WebAuthnPasswordlessAuthenticator {

    private static final Logger LOG = Logger.getLogger(WebAuthnConditionalMediationAuthenticator.class);

    public WebAuthnConditionalMediationAuthenticator(KeycloakSession session) {
        super(session);
    }

    @Override
    public void authenticate(AuthenticationFlowContext context) {
        super.authenticate(context);
        Response challenge = context.form()
                .createForm("webauthn-conditional-mediation-authenticate.ftl");
        context.challenge(challenge);
    }

    @Override
    public void action(AuthenticationFlowContext context) {
        MultivaluedMap<String, String> formData = context.getHttpRequest().getDecodedFormParameters();
        if (formData.containsKey("cancel")) {
            context.cancelLogin();
            return;
        }

        String username = formData.getFirst(AuthenticationManager.FORM_USERNAME);
        if (StringUtil.isNotBlank(username)) {
            boolean result = new UsernameForm().validateUser(context, formData);
            LOG.debugf("Username validate step result: %s", result);
            if(!result) return;
            context.attempted();
        }
        else {
            LOG.debugf("Continue with webauthn step ...");
            super.action(context);
        }
    }

    @Override
    public boolean requiresUser() {
        return false;
    }
}
