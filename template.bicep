param connections_twitter_name string = 'twitter'
param connections_keyvault_name string = 'keyvault'
param connections_linkedinv2_name string = 'linkedinv2'
param key_vault_name string = 'scxpstkv${uniqueString(resourceGroup().name)}'
param managed_identity_name string = 'scposter${uniqueString(resourceGroup().name)}'
param workflows_socialxposter_name string = 'socialxposterv2'
param resource_group_location string = resourceGroup().location
@secure()
param mastodon_key_value string
param mastodon_host string = 'mastodon.online'

// Key Vault and Secret

resource key_vault_resource 'Microsoft.KeyVault/vaults@2022-07-01' = {
  name: key_vault_name
  location: resource_group_location
  properties: {
    sku: {
      family: 'A'
      name: 'standard'
    }
    tenantId: subscription().tenantId
    accessPolicies: [
      {
        tenantId: subscription().tenantId
        objectId: managed_service_identity_kv_resource.properties.principalId
        permissions: {
          certificates: []
          keys: []
          secrets: [
            'get'
          ]
        }
      }
    ]
    enabledForDeployment: false
    enabledForDiskEncryption: false
    enabledForTemplateDeployment: false
    enableSoftDelete: true
    softDeleteRetentionInDays: 7
    enableRbacAuthorization: false
    publicNetworkAccess: 'Enabled'
  }
}

resource vaults_socialxpostkv_name_MastodonKey 'Microsoft.KeyVault/vaults/secrets@2022-07-01' = {
  parent: key_vault_resource
  name: 'MastodonKey'
  properties: {
    value: mastodon_key_value
    attributes: {
      enabled: true 
    }
  }
}

// End Key Vault and secret

// Managed Service Identity

resource managed_service_identity_kv_resource 'Microsoft.ManagedIdentity/userAssignedIdentities@2018-11-30' = {
  name: managed_identity_name
  location: resource_group_location
}

// End of Managed Service Identity

// Logic Apps Connection Definitions

resource connections_keyvault_resource 'Microsoft.Web/connections@2016-06-01' = {
  name: connections_keyvault_name
  location: resource_group_location
  properties: {
    displayName: 'KeyVaultMIAccess'
    parameterValueType: 'Alternative'
    alternativeParameterValues: {
      vaultName: key_vault_name
    }
    customParameterValues: {}
    api: {
      name: 'keyvault'
      displayName: 'Azure Key Vault'
      description: 'Azure Key Vault is a service to securely store and access secrets.'
      iconUri: 'https://connectoricons-prod.azureedge.net/releases/v1.0.1597/1.0.1597.3005/keyvault/icon.png'
      brandColor: '#0079d6'
      id: subscriptionResourceId('Microsoft.Web/locations/managedApis', resource_group_location, 'keyvault')
      type: 'Microsoft.Web/locations/managedApis'
    }
  }
}

resource connections_linkedinv2_resource 'Microsoft.Web/connections@2016-06-01' = {
  name: connections_linkedinv2_name
  location: resource_group_location
  properties: {
    displayName: 'LinkedIn V2'
    api: {
      name: connections_linkedinv2_name
      displayName: 'LinkedIn V2'
      description: 'Amplify your content\'s reach by easily sharing on LinkedIn. The connector targets LinkedIn API version 2.'
      iconUri: 'https://connectoricons-prod.azureedge.net/releases/v1.0.1604/1.0.1604.3062/linkedinv2/icon.png'
      brandColor: '#007AB9'
      id: subscriptionResourceId('Microsoft.Web/locations/managedApis', resource_group_location, 'linkedinv2')
      type: 'Microsoft.Web/locations/managedApis'
    }
  }
}

resource connections_twitter_name_resource 'Microsoft.Web/connections@2016-06-01' = {
  name: connections_twitter_name
  location: resource_group_location
  properties: {
    displayName: 'TwitterConnection'
    api: {
      name: connections_twitter_name
      displayName: 'Twitter'
      description: 'Twitter is an online social networking service that enables users to send and receive short messages called \'tweets\'. Connect to Twitter to manage your tweets. You can perform various actions such as send tweet, search, view followers, etc.'
      iconUri: 'https://connectoricons-prod.azureedge.net/releases/v1.0.1607/1.0.1607.3068/twitter/icon.png'
      brandColor: '#5fa9dd'
      id: subscriptionResourceId('Microsoft.Web/locations/managedApis', resource_group_location, 'twitter')
      type: 'Microsoft.Web/locations/managedApis'
    }
  }
}

// End Logic Apps Connection Definitions

// Azure Logic App

resource workflows_socialxposter_resource 'Microsoft.Logic/workflows@2019-05-01' = {
  name: workflows_socialxposter_name
  location: resource_group_location
  dependsOn: [
    managed_service_identity_kv_resource
  ]
  identity: {
    type: 'UserAssigned'
    userAssignedIdentities: {
      '/subscriptions/${subscription().subscriptionId}/resourceGroups/${resourceGroup().name}/providers/Microsoft.ManagedIdentity/userAssignedIdentities/${managed_service_identity_kv_resource.name}' : {}
    }
  }
  properties: {
    state: 'Enabled'
    definition: {
      '$schema': 'https://schema.management.azure.com/providers/Microsoft.Logic/schemas/2016-06-01/workflowdefinition.json#'
      contentVersion: '1.0.0.0'
      parameters: {
        '$connections': {
          defaultValue: {
          }
          type: 'Object'
        }
        MastodonHost: {
          defaultValue: mastodon_host
          type: 'String'
        }
      }
      triggers: {
        manual: {
          type: 'Request'
          kind: 'Http'
          inputs: {
            method: 'POST'
            schema: {
              properties: {
                ImageRef: {
                  type: 'string'
                }
                Link: {
                  type: 'string'
                }
                Summary: {
                  type: 'string'
                }
                Title: {
                  type: 'string'
                }
              }
              type: 'object'
            }
          }
        }
      }
      actions: {
        Get_secret: {
          runAfter: {
          }
          type: 'ApiConnection'
          inputs: {
            host: {
              connection: {
                name: '@parameters(\'$connections\')[\'keyvault\'][\'connectionId\']'
              }
            }
            method: 'get'
            path: '/secrets/@{encodeURIComponent(\'MastodonKey\')}/value'
          }
        }
        HTTP: {
          runAfter: {
            Get_secret: [
              'Succeeded'
            ]
          }
          type: 'Http'
          inputs: {
            body: 'status="@{triggerBody()?[\'Title\']}\n@{triggerBody()?[\'Summary\']}\n@{triggerBody()?[\'Link\']}"'
            headers: {
              Authorization: 'Bearer @{body(\'Get_secret\')?[\'value\']}'
              'Content-Type': 'application/x-www-form-urlencoded'
            }
            method: 'POST'
            uri: 'https://@{parameters(\'MastodonHost\')}/api/v1/statuses'
          }
        }
        Post_a_tweet: {
          runAfter: {
          }
          type: 'ApiConnection'
          inputs: {
            host: {
              connection: {
                name: '@parameters(\'$connections\')[\'twitter\'][\'connectionId\']'
              }
            }
            method: 'post'
            path: '/posttweet'
            queries: {
              tweetText: '@{triggerBody()?[\'Summary\']}\n@{triggerBody()?[\'Link\']}'
            }
          }
        }
        Share_an_article_V2: {
          runAfter: {
          }
          type: 'ApiConnection'
          inputs: {
            body: {
              content: {
                'content-image-url': '@triggerBody()?[\'ImageRef\']'
                'content-url': '@triggerBody()?[\'Link\']'
                title: '@triggerBody()?[\'Title\']'
              }
              distribution: {
                linkedInDistributionTarget: {
                  visibleToGuest: true
                }
              }
              text: {
                text: '@triggerBody()?[\'Summary\']'
              }
            }
            host: {
              connection: {
                name: '@parameters(\'$connections\')[\'linkedinv2\'][\'connectionId\']'
              }
            }
            method: 'post'
            path: '/v2/people/shares'
          }
        }
      }
      outputs: {
      }
    }
    parameters: {
      '$connections': {
        value: {
          keyvault: {
            connectionId: connections_keyvault_resource.id
            connectionName: 'keyvault'
            connectionProperties: {
              authentication: {
                type: 'ManagedServiceIdentity'
              }
            }
            id: subscriptionResourceId('Microsoft.Web/locations/managedApis', resource_group_location, 'keyvault')
          }
          linkedinv2: {
            connectionId: connections_linkedinv2_resource.id
            connectionName: 'linkedinv2'
            id: subscriptionResourceId('Microsoft.Web/locations/managedApis', resource_group_location, 'linkedinv2')
          }
          twitter: {
            connectionId: connections_twitter_name_resource.id
            connectionName: 'twitter'
            id: subscriptionResourceId('Microsoft.Web/locations/managedApis', resource_group_location, 'twitter')
          }
        }
      }
    }
  }
}

// End of Azure Logic App
