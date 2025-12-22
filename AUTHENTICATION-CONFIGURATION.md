AUTHENTICATION-CONFIGURATION.md
# Auth0 and KrakenD Configuration Guide

## Prerequisites
Complete these configurations **before** running `./01cloud install`.

## 1. Auth0 Setup

### 1.1 Create Auth0 Account
1. Go to [auth0.com](https://auth0.com) and create an account
2. Create a new tenant

### 1.2 Create Single Page Application
1. Navigate to **Applications** → **Create Application**
2. Select **Single Page Web Applications**
3. Configure URLs:
   - **Allowed Callback URLs**: `http://localhost:3000/callback`, `https://your-domain.com/callback`
   - **Allowed Logout URLs**: `http://localhost:3000`, `https://your-domain.com`
   - **Allowed Web Origins**: `http://localhost:3000`, `https://your-domain.com`

### 1.3 Create Admin User
Create a user with these credentials (required for database seeder):
- **Email**: `admin@admin`
- **Password**: `01cloud@2020`
- **Connection**: `Username-Password-Authentication`

### 1.4 Create Post-Login Action
1. Navigate to **Actions** → **Triggers**
2. Select **Post Login** → **Create Custom Action**
3. Name the action (e.g., "Set Custom Claims")
4. Copy and paste the following code:

```javascript
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

5. Click **Deploy** to save the action

### 1.5 Save Auth0 Configuration Values
Save these values for later use:

| Parameter | Location | Example |
|-----------|----------|---------|
| **Domain** | Application → Settings → Domain | `your-tenant.auth0.com` |
| **Client ID** | Application → Settings | `your_client_id_here` |
| **Audience** | Applications → API → API Identifier | `https://api.01cloud.com` |

## 2. KrakenD Configuration

### 2.1 Prepare Gateway Templates
1. Navigate to the gateway directory:
   ```bash
   cd gateway
   ```
2. Extract the template files:
   ```bash
   tar -xzf krakend-templates.tgz
   ```

### 2.2 Update Auth0 Template Files
Update the following template files with your Auth0 values:

**File:** `gateway/config/dev/partials/auth0_audience.tmpl`
```json
"https://{domain-name}.us.auth0.com/api/v2/"
```
Replace with your actual API audience (e.g., `"https://api.01cloud.com"`)

**File:** `gateway/config/dev/partials/auth0_jwk_url.tmpl`
```json
"https://{{ .auth0_domain }}/.well-known/jwks.json"
```
Replace `{{ .auth0_domain }}` with your Auth0 tenant domain (e.g., `your-tenant.auth0.com`)

**File:** `gateway/config/dev/partials/auth0_validator.tmpl`
```json
{
  "audience": "https://{domain-name}.us.auth0.com/api/v2/",
  "jwk_url": "https://{{ .auth0_domain }}/.well-known/jwks.json",
}
```
Update both `audience` and `jwk_url` with your actual values.

### 2.3 Generate KrakenD Configuration
From the project root directory (`01cloud-platform/`), run:

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

**Note:** This command will automatically update the `krakend.json` file in the KrakenD Helm chart.

## 3. Update UI Configuration

### 3.1 Console UI ConfigMap
Update the following environment variables:

```yaml
REACT_APP_AUTH0_DOMAIN: "your-tenant.auth0.com"
REACT_APP_AUTH0_CLIENT_ID: "your_client_id"
REACT_APP_AUTH0_AUDIENCE: "https://your-tenant.auth0.com/api/v2/"
```

### 3.2 Admin UI ConfigMap
Update the following environment variables:

```yaml
REACT_APP_AUTH0_DOMAIN: "your-tenant.auth0.com"
REACT_APP_AUTH0_CLIENT_ID: "your_client_id"
REACT_APP_AUTH0_AUDIENCE: "https://your-tenant.auth0.com/api/v2/"
```

## 4. Installation

After completing all configurations, run the installation script:

```bash
./01cloud install
```

## Troubleshooting

- **Missing templates**: Ensure you've extracted `krakend-templates.tgz` in the gateway directory
- **Invalid JSON**: Verify your Auth0 values are correctly formatted in the template files
- **Authentication failures**: Double-check that all URLs and domains match exactly between Auth0 and your configuration
