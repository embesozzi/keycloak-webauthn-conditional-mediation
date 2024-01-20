package com.twogenidentity.keycloak.authenticator;

import jakarta.ws.rs.core.MultivaluedMap;
import jakarta.ws.rs.core.Response;
import org.jboss.logging.Logger;
import org.keycloak.authentication.AuthenticationFlowContext;
import org.keycloak.authentication.Authenticator;
import org.keycloak.forms.login.freemarker.model.WebAuthnAuthenticatorsBean;
import org.keycloak.models.KeycloakSession;
import org.keycloak.models.RealmModel;
import org.keycloak.models.UserModel;
import org.keycloak.sessions.AuthenticationSessionModel;

public class WebAuthnConditionalEnrollmentAuthenticator implements Authenticator {
    private static final Logger LOG = Logger.getLogger(WebAuthnConditionalEnrollmentAuthenticator.class);

    private static final String TEMPLATE_NAME = "webauthn-conditional-enrollment.ftl";

    private static final String FORM_PARAM_USER_CONFIRM_ANSWER = "user-confirm-answer";

    public void authenticate(AuthenticationFlowContext context) {
        if (userHasWebAuthnAuthenticator(context).booleanValue()) {
            LOG.debugf("User already registered webauthn authenticator", new Object[0]);
            context.success();
            return;
        }
        Response challenge = context.form().createForm("webauthn-conditional-enrollment.ftl");
        context.challenge(challenge);
    }

    private Boolean userHasWebAuthnAuthenticator(AuthenticationFlowContext context) {
        UserModel user = context.getUser();
        if (user != null) {
            LOG.debugf("Looking for webauthn-passworless authenticator...", new Object[0]);
            WebAuthnAuthenticatorsBean authenticators = new WebAuthnAuthenticatorsBean(context.getSession(), context.getRealm(), user, "webauthn-passwordless");
            if (authenticators.getAuthenticators().isEmpty()) {
                LOG.debugf("Looking for webauthn authenticator...", new Object[0]);
                authenticators = new WebAuthnAuthenticatorsBean(context.getSession(), context.getRealm(), user, "webauthn");
            }
            return Boolean.valueOf(!authenticators.getAuthenticators().isEmpty());
        }
        return Boolean.valueOf(false);
    }

    public void action(AuthenticationFlowContext context) {
        MultivaluedMap<String, String> formData = context.getHttpRequest().getDecodedFormParameters();
        String answer = (String)formData.getFirst("user-confirm-answer");
        LOG.debugf("Username answer is: %s", answer);
        if ("yes".equalsIgnoreCase(answer)) {
            AuthenticationSessionModel authenticationSession = context.getAuthenticationSession();
            if (!authenticationSession.getRequiredActions().contains("webauthn-register-passwordless"))
                authenticationSession.addRequiredAction("webauthn-register-passwordless");
        }
        context.success();
    }

    public boolean requiresUser() {
        return false;
    }

    public boolean configuredFor(KeycloakSession keycloakSession, RealmModel realmModel, UserModel userModel) {
        return true;
    }

    public void setRequiredActions(KeycloakSession keycloakSession, RealmModel realmModel, UserModel userModel) {}

    public void close() {}
}

