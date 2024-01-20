package com.twogenidentity.keycloak.authenticator;

import org.keycloak.Config;
import org.keycloak.authentication.Authenticator;
import org.keycloak.authentication.AuthenticatorFactory;
import org.keycloak.models.AuthenticationExecutionModel;
import org.keycloak.models.KeycloakSession;
import org.keycloak.models.KeycloakSessionFactory;
import org.keycloak.provider.ProviderConfigProperty;

import java.util.List;

public class WebAuthnConditionalEnrollmentAuthenticatorFactory implements AuthenticatorFactory {
    private static final AuthenticationExecutionModel.Requirement[] REQUIREMENT_CHOICES = new AuthenticationExecutionModel.Requirement[] { AuthenticationExecutionModel.Requirement.REQUIRED, AuthenticationExecutionModel.Requirement.DISABLED };

    static final String PROVIDER_ID = "webauthn-conditional-enrollment";

    public String getDisplayType() {
        return "WebAuthn conditional enrollment";
    }

    public String getReferenceCategory() {
        return "WebAuthn Enrollment";
    }

    public boolean isConfigurable() {
        return true;
    }

    public AuthenticationExecutionModel.Requirement[] getRequirementChoices() {
        return REQUIREMENT_CHOICES;
    }

    public boolean isUserSetupAllowed() {
        return false;
    }

    public String getHelpText() {
        return "Allows user to enroll for WebAuthn device";
    }

    public List<ProviderConfigProperty> getConfigProperties() {
        return null;
    }

    public Authenticator create(KeycloakSession keycloakSession) {
        return new WebAuthnConditionalEnrollmentAuthenticator();
    }

    public void init(Config.Scope scope) {}

    public void postInit(KeycloakSessionFactory keycloakSessionFactory) {}

    public void close() {}

    public String getId() {
        return "webauthn-conditional-enrollment";
    }
}
