import { http } from '@wagmi/core'
import { getDefaultConfig } from '@rainbow-me/rainbowkit'

const monadTestnet = {
  id: 10143,
  name: 'Monad Testnet',
  nativeCurrency: {
    decimals: 18,
    name: 'Monad',
    symbol: 'MON',
  },
  rpcUrls: {
    default: {
      http: ['https://testnet-rpc.monad.xyz'],
    },
  },
  blockExplorers: {
    default: {
      name: 'Monadscan',
      url: 'https://testnet.monadscan.com',
    },
  },
  testnet: true,
} as const

const projectId = process.env.NEXT_PUBLIC_WALLETCONNECT_PROJECT_ID || ''

export const wagmiConfig =
  typeof window === 'undefined'
    ? undefined
    : getDefaultConfig({
        appName: 'SocialPayments',
        projectId,
        chains: [monadTestnet],
        ssr: false,
        transports: {
          [monadTestnet.id]: http('https://testnet-rpc.monad.xyz'),
        },
      })
