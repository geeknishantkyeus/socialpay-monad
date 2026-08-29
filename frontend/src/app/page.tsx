'use client'

import { useState, useEffect } from 'react'
import { ConnectButton } from '@rainbow-me/rainbowkit'
import { useAccount, useReadContract, useWriteContract } from 'wagmi'
import { parseEther } from 'viem'
import SocialPaymentsABI from '../../abi/SocialPayments.json'

// ✅ Read contract address from environment variable
const CONTRACT_ADDRESS =
  (process.env.NEXT_PUBLIC_CONTRACT_ADDRESS as `0x${string}`) ||
  '0x05Fb5b5EcD28a3d6e1380f4dAA920BD950c98C31'

export default function Home() {
  const { address, isConnected } = useAccount()
  const [mounted, setMounted] = useState(false)
  const [username, setUsername] = useState('')
  const [recipient, setRecipient] = useState('')
  const [amount, setAmount] = useState('')
  const [note, setNote] = useState('')
  const [userReputation, setUserReputation] = useState(0)
  const [userUsername, setUserUsername] = useState('')
  const [paymentHistory, setPaymentHistory] = useState<any[]>([])

  useEffect(() => {
    setMounted(true)
  }, [])

  const { data: usernameData } = useReadContract({
    address: CONTRACT_ADDRESS,
    abi: SocialPaymentsABI,
    functionName: 'getUserUsername',
    args: [address as `0x${string}`],
    query: {
      enabled: !!address,
    },
  })

  const { data: reputationData } = useReadContract({
    address: CONTRACT_ADDRESS,
    abi: SocialPaymentsABI,
    functionName: 'getUserReputation',
    args: [address as `0x${string}`],
    query: {
      enabled: !!address,
    },
  })

  const { data: historyData } = useReadContract({
    address: CONTRACT_ADDRESS,
    abi: SocialPaymentsABI,
    functionName: 'getPaymentHistory',
    args: [address as `0x${string}`],
    query: {
      enabled: !!address,
    },
  })

  const { writeContract: registerUser, isPending: registerLoading } = useWriteContract()
  const { writeContract: sendPayment, isPending: paymentLoading } = useWriteContract()

  const handleRegister = () => {
    if (username) {
      registerUser({
        address: CONTRACT_ADDRESS,
        abi: SocialPaymentsABI,
        functionName: 'registerUser',
        args: [username],
      })
    }
  }

  const handleSendPayment = () => {
    if (recipient && amount && note) {
      sendPayment({
        address: CONTRACT_ADDRESS,
        abi: SocialPaymentsABI,
        functionName: 'sendPayment',
        args: [recipient, note],
        value: parseEther(amount),
      })
    }
  }

  useEffect(() => {
    if (reputationData !== undefined) setUserReputation(Number(reputationData))
    if (usernameData) setUserUsername(String(usernameData))
    if (historyData) setPaymentHistory((historyData as any[]) ?? [])
  }, [reputationData, usernameData, historyData])

  if (!mounted) return null

  return (
    <main className="min-h-screen bg-gray-50 p-8">
      <div className="mx-auto max-w-3xl">
        <div className="mb-8 flex items-center justify-between">
          <h1 className="text-3xl font-bold text-purple-600">SocialPay</h1>
          <ConnectButton />
        </div>

        {isConnected ? (
          <div className="space-y-6">
            <div className="rounded-lg bg-white p-6 shadow">
              <h2 className="mb-4 text-xl font-semibold">Your Profile</h2>
              <p>
                <strong>Address:</strong> {address?.slice(0, 6)}...{address?.slice(-4)}
              </p>
              <p>
                <strong>Username:</strong> {userUsername || 'Not registered'}
              </p>
              <p>
                <strong>Reputation:</strong> {userReputation}
              </p>
            </div>

            {!userUsername && (
              <div className="rounded-lg bg-white p-6 shadow">
                <h2 className="mb-4 text-xl font-semibold">Register Username</h2>
                <div className="flex gap-2">
                  <input
                    type="text"
                    placeholder="Enter username"
                    value={username}
                    onChange={(e) => setUsername(e.target.value)}
                    className="flex-1 rounded border px-4 py-2"
                  />
                  <button
                    onClick={handleRegister}
                    disabled={registerLoading || !username}
                    className="rounded bg-purple-600 px-6 py-2 text-white hover:bg-purple-700 disabled:opacity-50"
                  >
                    {registerLoading ? 'Registering...' : 'Register'}
                  </button>
                </div>
              </div>
            )}

            <div className="rounded-lg bg-white p-6 shadow">
              <h2 className="mb-4 text-xl font-semibold">Send Payment</h2>
              <div className="space-y-3">
                <input
                  type="text"
                  placeholder="Recipient Address (0x...)"
                  value={recipient}
                  onChange={(e) => setRecipient(e.target.value)}
                  className="w-full rounded border px-4 py-2"
                />
                <input
                  type="text"
                  placeholder="Amount in MON"
                  value={amount}
                  onChange={(e) => setAmount(e.target.value)}
                  className="w-full rounded border px-4 py-2"
                />
                <input
                  type="text"
                  placeholder="Note (optional)"
                  value={note}
                  onChange={(e) => setNote(e.target.value)}
                  className="w-full rounded border px-4 py-2"
                />
                <button
                  onClick={handleSendPayment}
                  disabled={paymentLoading || !recipient || !amount}
                  className="w-full rounded bg-green-600 py-2 text-white hover:bg-green-700 disabled:opacity-50"
                >
                  {paymentLoading ? 'Sending...' : 'Send Payment'}
                </button>
              </div>
            </div>

            <div className="rounded-lg bg-white p-6 shadow">
              <h2 className="mb-4 text-xl font-semibold">Payment History</h2>
              {paymentHistory.length === 0 ? (
                <p className="text-gray-500">No payments yet</p>
              ) : (
                <div className="space-y-2">
                  {paymentHistory.map((payment: any, index: number) => (
                    <div key={index} className="border-b pb-2">
                      <p>
                        <strong>From:</strong> {payment.from}
                      </p>
                      <p>
                        <strong>To:</strong> {payment.to}
                      </p>
                      <p>
                        <strong>Amount:</strong> {payment.amount} MON
                      </p>
                      <p>
                        <strong>Note:</strong> {payment.note}
                      </p>
                      <p className="text-sm text-gray-500">
                        {new Date(Number(payment.timestamp) * 1000).toLocaleString()}
                      </p>
                    </div>
                  ))}
                </div>
              )}
            </div>
          </div>
        ) : (
          <div className="py-20 text-center">
            <h2 className="mb-4 text-2xl font-semibold">Connect Your Wallet</h2>
            <p className="text-gray-600">Click the Connect Wallet button above to get started</p>
          </div>
        )}
      </div>
    </main>
  )
}
