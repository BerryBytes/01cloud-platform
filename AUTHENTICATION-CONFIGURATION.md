Auth0 and KrakenD Configuration Guide
=====================================

Prerequisites
-------------

Complete these configurations before running ./01cloud install.

1\. Auth0 Setup
---------------

### Create Auth0 Account

1.  Go to [auth0.com](https://auth0.com) and create an account

2.  Create a new tenant


### Create Single Page Application

1.  Navigate to **Applications** → **Create Application**

2.  Select **Single Page Web Applications**

3.  Configure URLs:

    *   **Allowed Callback URLs**: http://localhost:3000/callback, https://your-domain.com/callback

    *   **Allowed Logout URLs**: http://localhost:3000, https://your-domain.com

    *   **Allowed Web Origins**: http://localhost:3000, https://your-domain.com



### Create  User

Create user with these credentials (required for database seeder):

*   **Email**: admin@admin

*   **Password**: 01cloud@2020

*   **Connection**: Username-Password-Authentication

### Create Action

* Navigate to the **Actions** - **Triggers**
* Select the **post-login** - **create custom action**


```json
exports.onExecutePostLogin = async (event, api) => {
  const namespace = 'https://myapp.com/'; // Must be a valid URI

  // Helper function to safely get string values
  const getString = (value) => {
    if (typeof value === 'string' && value.trim()) {
      return value.trim();
    }
    return null;
  };

  // Get name components with better fallback logic
  let firstName = getString(event.user.given_name);
  let lastName = getString(event.user.family_name);

  // Apply fallback only if both are missing
  if (!firstName && !lastName) {
    const fullName = getString(event.user.name);
    const nickname = getString(event.user.nickname);
    const emailUsername = event.user.email ? event.user.email.split('@')[0].trim() : null;

    if (fullName) {
      const parts = fullName.split(/\s+/);
      firstName = parts[0] || null;
      lastName = parts.length > 1 ? parts.slice(1).join(' ') : null;
    } else if (nickname) {
      firstName = nickname;
      lastName = null;
    } else if (emailUsername) {
      firstName = emailUsername;
      lastName = null;
    }
  }

  // Ensure we have strings (not null) for names to avoid issues
  firstName = firstName || '-';
  lastName = lastName || '-';

  // Build profile object with proper null handling
  const profile = {
    email: getString(event.user.email),
    email_verified: Boolean(event.user.email_verified),
    first_name: firstName,
    last_name: lastName,
    image: getString(event.user.picture),
    name: getString(event.user.name),
    created_at: event.user.created_at || null,
    updated_at: event.user.updated_at || null,
    company: null,
    designation: null,
    active: true,
    is_admin: false,
    address_updated: false,
    quotas: null,
    used_demo: false,
    reference: null
  };

  try {
    // Set each profile key as an individual custom claim
    Object.entries(profile).forEach(([key, value]) => {
      api.accessToken.setCustomClaim(`${namespace}${key}`, value);
    });

    // Set roles if available
    const roles = event.authorization?.roles || [];
    api.accessToken.setCustomClaim(`${namespace}roles`, roles);

  } catch (error) {
    console.error('Error setting custom claims:', error);
    // You might want to handle this error based on your requirements
    // For now, we'll let the login continue even if claims fail
  }
};

```



### Save Auth0 Values

ParameterLocation

**Domain** Application → Settings → your-tenant.auth0.com

**Client ID** Application → Settings

**Audience** Applications → API → API Audience

2\. KrakenD Configuration
-------------------------

### Update Auth0 Settings

Update Auth0 Partial Templates

After configuring Auth0, update the following template files with your Auth0 values:

```
File: gateway/config/dev/partials/auth0_audience.tmpl
```
```json
"https://{domain-name}.us.auth0.com/api/v2/"
```
Update the audience value to match your Auth0 API identifier (e.g., https://api.01cloud.com)

File: gateway/config/dev/partials/auth0_jwk_url.tmpl
```json
"https://{{ .auth0_domain }}/.well-known/jwks.json"
```
Update the domain value to your Auth0 tenant domain (e.g., your-tenant.auth0.com)

File: gateway/config/dev/partials/auth0_validator.tmpl
```json
{
  "audience": "https://{domain-name}.us.auth0.com/api/v2/",
  "jwk_url": "https://{{ .auth0_domain }}/.well-known/jwks.json",
}
```

Generate KrakenD JSON
Run from /home/berrybytes/01cloud-platform/gateway:

```bash
docker run \
  --rm -it \
  --user "$(id -u):$(id -g)" \
  -p "8080:8080" \
  -v "$PWD:/etc/krakend" \
  -e FC_ENABLE=1 \
  -e FC_SETTINGS=gateway/config/dev/settings/prod \
  -e FC_PARTIALS=gateway/config/dev/partials \
  -e FC_TEMPLATES=gateway/config/common/templates \
  -e FC_OUT=/etc/krakend/gateway/krakend/files/krakend.json \
  -e SERVICE_NAME="KrakenD API Gateway" \
  krakend:2.10.0 check -tdc "krakend.tmpl"
```
Note: It will auto update the krakend json file in the krakend helm chart

3. Update UI ConfigMaps
-------------------------
Console UI
```yaml
REACT_APP_AUTH0_DOMAIN: "your-tenant.auth0.com"
REACT_APP_AUTH0_CLIENT_ID: "your_client_id"
REACT_APP_AUTH0_AUDIENCE: "https://{{ .auth0_domain }}/.well-known/jwks.json"
```
Admin UI
```yaml
REACT_APP_AUTH0_DOMAIN: "your-tenant.auth0.com"
REACT_APP_AUTH0_CLIENT_ID: "your_client_id"
REACT_APP_AUTH0_AUDIENCE: "https://{{ .auth0_domain }}/.well-known/jwks.json"
```

## 4. Installation

After completing all configurations, run the installation script:

```bash
./01cloud install
