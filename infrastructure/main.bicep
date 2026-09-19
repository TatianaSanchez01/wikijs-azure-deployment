targetScope = 'resourceGroup'

// ============================================================
// PARÁMETROS
// ============================================================

@description('Región de Azure donde se desplegarán los recursos.')
param location string = 'chilecentral'

@description('Nombre de la máquina virtual.')
param vmName string = 'wikijs-vm'

@description('Tamaño de la máquina virtual.')
param vmSize string = 'Standard_D2s_v4'

@description('Nombre de usuario administrador para acceder por SSH.')
param adminUsername string = 'azureadmin'

@description('Nombre de la red virtual.')
param virtualNetworkName string = 'wikijs-vnet'

@description('Nombre de la subred.')
param subnetName string = 'wikijs-subnet'

@description('Nombre del grupo de seguridad de red.')
param networkSecurityGroupName string = 'wikijs-nsg'

@description('Nombre de la dirección IP pública.')
param publicIpName string = 'wikijs-public-ip'

@description('Nombre de la interfaz de red.')
param networkInterfaceName string = 'wikijs-nic'

@description('Clave pública SSH utilizada para acceder a la máquina virtual.')
param sshPublicKey string


// ============================================================
// VARIABLES
// ============================================================

var subnetAddressPrefix = '10.0.1.0/24'
var virtualNetworkAddressPrefix = '10.0.0.0/16'


// ============================================================
// GRUPO DE SEGURIDAD DE RED
// ============================================================

resource networkSecurityGroup 'Microsoft.Network/networkSecurityGroups@2024-05-01' = {
  name: networkSecurityGroupName
  location: location

  properties: {
    securityRules: [
      {
        name: 'Allow-SSH'
        properties: {
          priority: 1000
          access: 'Allow'
          direction: 'Inbound'
          protocol: 'Tcp'
          sourcePortRange: '*'
          destinationPortRange: '22'
          sourceAddressPrefix: '*'
          destinationAddressPrefix: '*'
        }
      }
      {
        name: 'Allow-HTTP'
        properties: {
          priority: 1010
          access: 'Allow'
          direction: 'Inbound'
          protocol: 'Tcp'
          sourcePortRange: '*'
          destinationPortRange: '80'
          sourceAddressPrefix: '*'
          destinationAddressPrefix: '*'
        }
      }
    ]
  }
}


// ============================================================
// RED VIRTUAL Y SUBRED
// ============================================================

resource virtualNetwork 'Microsoft.Network/virtualNetworks@2024-05-01' = {
  name: virtualNetworkName
  location: location

  properties: {
    addressSpace: {
      addressPrefixes: [
        virtualNetworkAddressPrefix
      ]
    }

    subnets: [
      {
        name: subnetName
        properties: {
          addressPrefix: subnetAddressPrefix
          networkSecurityGroup: {
            id: networkSecurityGroup.id
          }
        }
      }
    ]
  }
}


// ============================================================
// IP PÚBLICA
// ============================================================

resource publicIp 'Microsoft.Network/publicIPAddresses@2024-05-01' = {
  name: publicIpName
  location: location

  sku: {
    name: 'Standard'
  }

  properties: {
    publicIPAllocationMethod: 'Static'
  }
}


// ============================================================
// INTERFAZ DE RED
// ============================================================

resource networkInterface 'Microsoft.Network/networkInterfaces@2024-05-01' = {
  name: networkInterfaceName
  location: location

  properties: {
    ipConfigurations: [
      {
        name: 'ipconfig1'

        properties: {
          privateIPAllocationMethod: 'Dynamic'

          publicIPAddress: {
            id: publicIp.id
          }

          subnet: {
            id: resourceId(
              'Microsoft.Network/virtualNetworks/subnets',
              virtualNetworkName,
              subnetName
            )
          }
        }
      }
    ]
  }

  dependsOn: [
    virtualNetwork
  ]
}


// ============================================================
// MÁQUINA VIRTUAL
// ============================================================

resource virtualMachine 'Microsoft.Compute/virtualMachines@2024-07-01' = {
  name: vmName
  location: location

  properties: {
    hardwareProfile: {
      vmSize: vmSize
    }

    storageProfile: {
      imageReference: {
        publisher: 'Canonical'
        offer: 'ubuntu-24_04-lts'
        sku: 'server'
        version: 'latest'
      }

      osDisk: {
        createOption: 'FromImage'
        managedDisk: {
          storageAccountType: 'StandardSSD_LRS'
        }
      }
    }

    osProfile: {
      computerName: vmName
      adminUsername: adminUsername

      linuxConfiguration: {
        disablePasswordAuthentication: true

        ssh: {
          publicKeys: [
            {
              path: '/home/${adminUsername}/.ssh/authorized_keys'
              keyData: sshPublicKey
            }
          ]
        }
      }
    }

    networkProfile: {
      networkInterfaces: [
        {
          id: networkInterface.id
        }
      ]
    }
  }

}


// ============================================================
// SALIDAS
// ============================================================

output vmName string = virtualMachine.name
output publicIpAddress string = publicIp.properties.ipAddress
output resourceGroupName string = resourceGroup().name
