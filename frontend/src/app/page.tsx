'use client'

import { useState, useEffect } from 'react'
import { ConnectButton } from '@rainbow-me/rainbowkit'
import { useAccount, useReadContract, useWriteContract, useWaitForTransactionReceipt } from 'wagmi'
import { parseEther, formatEther } from 'viem'
import toast from 'react-hot-toast'
import SocialPaymentsABI from '../../abi/SocialPayments.json'

const CONTRACT_ADDRESS = '0x0F40999C09C85Dc9548170204C845C3BBf8780E0'

function WalletContent() {
  const { address, isConnected } = useAccount()
  const [username, setUsername] = useState('')
  const [recipientInput, setRecipientInput] = useState('')
  const [amount, setAmount] = useState('')
  const [note, setNote] = useState('')
  const [userReputation, setUserReputation] = useState(0)
  const [userUsername, setUserUsername] = useState('')
  const [paymentHistory, setPaymentHistory] = useState<any[]>([])

  const { data: usernameData, refetch: refetchUsername } = useReadContract({
    address: CONTRACT_ADDRESS,
    abi: SocialPaymentsABI,
    functionName: 'getUserUsername',
    args: [address as `0x${string}`],
    query: { enabled: !!address },
  })

  const { data: reputationData, refetch: refetchReputation } = useReadContract({
    address: CONTRACT_ADDRESS,
    abi: SocialPaymentsABI,
    functionName: 'getUserReputation',
    args: [address as `0x${string}`],
    query: { enabled: !!address },
  })

  const { data: historyData, refetch: refetchHistory } = useReadContract({
    address: CONTRACT_ADDRESS,
    abi: SocialPaymentsABI,
    functionName: 'getPaymentHistory',
    args: [address as `0x${string}`],
    query: { enabled: !!address },
  })

  // Read address from username if input is a username
  const cleanUsername = recipientInput.startsWith('@') 
    ? recipientInput.slice(1).trim().toLowerCase() 
    : recipientInput.trim().toLowerCase()
  const { data: resolvedFromUsername } = useReadContract({
    address: CONTRACT_ADDRESS,
    abi: SocialPaymentsABI,
    functionName: 'getAddressByUsername',
    args: [cleanUsername],
    query: { enabled: !!cleanUsername && !recipientInput.startsWith('0x') },
  })

  const { writeContract: registerUser, isPending: registerLoading, data: registerHash } = useWriteContract()
  const { writeContract: sendPayment, isPending: paymentLoading, data: paymentHash } = useWriteContract()

  const { isLoading: isRegisterConfirming, isSuccess: isRegisterSuccess } = useWaitForTransactionReceipt({
    hash: registerHash,
  })

  const { isLoading: isPaymentConfirming, isSuccess: isPaymentSuccess } = useWaitForTransactionReceipt({
    hash: paymentHash,
  })

  useEffect(() => {
    if (reputationData !== undefined) setUserReputation(Number(reputationData))
    if (usernameData) setUserUsername(String(usernameData))
    if (historyData) setPaymentHistory((historyData as any[]) ?? [])
  }, [reputationData, usernameData, historyData])

  useEffect(() => {
    if (isRegisterSuccess) {
      toast.success('Username registered successfully!')
      refetchUsername()
      refetchReputation()
      refetchHistory()
    }
  }, [isRegisterSuccess])

  useEffect(() => {
    if (isPaymentSuccess) {
      toast.success('Payment sent successfully!')
      setAmount('')
      setRecipientInput('')
      setNote('')
      refetchUsername()
      refetchReputation()
      refetchHistory()
    }
  }, [isPaymentSuccess])

  useEffect(() => {
    if (address) {
      refetchUsername()
      refetchReputation()
      refetchHistory()
    }
  }, [address])

  const handleRegister = () => {
    if (username) {
      const normalizedUsername = username.trim().toLowerCase()
      try {
        registerUser({
          address: CONTRACT_ADDRESS,
          abi: SocialPaymentsABI,
          functionName: 'registerUser',
          args: [normalizedUsername],
        })
      } catch (error) {
        toast.error('Registration failed: ' + (error as Error).message)
      }
    }
  }

  const handleSendPayment = () => {
    const isAddress = recipientInput.startsWith('0x') && recipientInput.length === 42
    const finalRecipient = isAddress
      ? recipientInput
      : resolvedFromUsername && resolvedFromUsername !== '0x0000000000000000000000000000000000000000'
      ? (resolvedFromUsername as string)
      : null

    if (!finalRecipient) {
      toast.error('Recipient not found or invalid address')
      return
    }

    if (finalRecipient && amount) {
      try {
        sendPayment({
          address: CONTRACT_ADDRESS,
          abi: SocialPaymentsABI,
          functionName: 'sendPayment',
          args: [finalRecipient as `0x${string}`, note || ""],
          value: parseEther(amount),
        })
      } catch (error) {
        toast.error('Payment failed: ' + (error as Error).message)
      }
    }
  }

  return (
    <main className="min-h-screen bg-[#0a0a0a] p-8">
      <div className="mx-auto max-w-3xl">
        <div className="mb-8 flex items-center justify-between">
          <h1 className="text-3xl font-bold text-purple-500">SocialPay</h1>
          <ConnectButton />
        </div>

        {isConnected ? (
          <div className="space-y-6">
            <div className="rounded-lg bg-[#1a1a1a] p-6 shadow-2xl shadow-purple-900/5 border border-[#2a2a2a]">
              <h2 className="mb-4 text-xl font-semibold text-white">Your Profile</h2>
              <p className="text-gray-300"><strong className="text-white">Address:</strong> {address?.slice(0, 6)}...{address?.slice(-4)}</p>
              <p className="text-gray-300"><strong className="text-white">Username:</strong> {userUsername?.toLowerCase() || 'Not registered'}</p>
              <p className="text-gray-300"><strong className="text-white">Reputation:</strong> {userReputation}</p>
            </div>

            {!userUsername && (
              <div className="rounded-lg bg-[#1a1a1a] p-6 shadow-2xl shadow-purple-900/5 border border-[#2a2a2a]">
                <h2 className="mb-4 text-xl font-semibold text-white">Register Username</h2>
                <div className="flex gap-2">
                  <input
                    type="text"
                    placeholder="Enter username"
                    value={username}
                    onChange={(e) => setUsername(e.target.value)}
                    className="flex-1 rounded-lg border border-[#2a2a2a] bg-[#0a0a0a] px-4 py-2 text-white placeholder-gray-500 focus:border-purple-500 focus:outline-none"
                  />
                  <button
                    onClick={handleRegister}
                    disabled={registerLoading || isRegisterConfirming || !username}
                    className="rounded-lg bg-gradient-to-r from-purple-600 to-purple-800 px-6 py-2 font-semibold text-white transition hover:scale-105 hover:shadow-lg hover:shadow-purple-500/25 disabled:opacity-50"
                  >
                    {registerLoading ? 'Confirm in wallet...' : isRegisterConfirming ? 'Confirming...' : 'Register'}
                  </button>
                </div>
              </div>
            )}

            <div className="rounded-lg bg-[#1a1a1a] p-6 shadow-2xl shadow-purple-900/5 border border-[#2a2a2a]">
              <h2 className="mb-4 text-xl font-semibold text-white">Send Payment</h2>
              <div className="space-y-3">
                <div>
                  <input
                    type="text"
                    placeholder="Recipient Address (0x...) or Username"
                    value={recipientInput}
                    onChange={(e) => setRecipientInput(e.target.value)}
                    className="w-full rounded-lg border border-[#2a2a2a] bg-[#0a0a0a] px-4 py-2 text-white placeholder-gray-500 focus:border-purple-500 focus:outline-none"
                  />
                  {recipientInput && !recipientInput.startsWith('0x') && resolvedFromUsername && resolvedFromUsername !== '0x0000000000000000000000000000000000000000' && (
                    <p className="mt-1 text-sm text-purple-400">
                      Resolved: {(resolvedFromUsername as string).slice(0, 6)}...{(resolvedFromUsername as string).slice(-4)}
                    </p>
                  )}
                </div>
                <input
                  type="text"
                  placeholder="Amount in MON"
                  value={amount}
                  onChange={(e) => setAmount(e.target.value)}
                  className="w-full rounded-lg border border-[#2a2a2a] bg-[#0a0a0a] px-4 py-2 text-white placeholder-gray-500 focus:border-purple-500 focus:outline-none"
                />
                <input
                  type="text"
                  placeholder="Note (optional)"
                  value={note}
                  onChange={(e) => setNote(e.target.value)}
                  className="w-full rounded-lg border border-[#2a2a2a] bg-[#0a0a0a] px-4 py-2 text-white placeholder-gray-500 focus:border-purple-500 focus:outline-none"
                />
                <button
                  onClick={handleSendPayment}
                  disabled={paymentLoading || isPaymentConfirming || !recipientInput || !amount}
                  className="w-full rounded-lg bg-gradient-to-r from-green-600 to-green-800 py-2 font-semibold text-white transition hover:scale-105 hover:shadow-lg hover:shadow-green-500/25 disabled:opacity-50"
                >
                  {paymentLoading ? 'Confirm in wallet...' : isPaymentConfirming ? 'Confirming...' : 'Send Payment'}
                </button>
              </div>
            </div>

            <div className="rounded-lg bg-[#1a1a1a] p-6 shadow-2xl shadow-purple-900/5 border border-[#2a2a2a]">
              <h2 className="mb-4 text-xl font-semibold text-white">Payment History</h2>
              {paymentHistory.length === 0 ? (
                <p className="text-gray-500">No payments yet</p>
              ) : (
                <div className="space-y-2">
                  {paymentHistory.map((payment: any, index: number) => (
                    <div key={index} className="rounded-lg border border-[#2a2a2a] bg-[#0a0a0a] p-3">
                      <p className="text-sm text-gray-300"><strong className="text-white">From:</strong> {payment.from.slice(0, 6)}...{payment.from.slice(-4)}</p>
                      <p className="text-sm text-gray-300"><strong className="text-white">To:</strong> {payment.to.slice(0, 6)}...{payment.to.slice(-4)}</p>
                      <p className="text-sm text-gray-300"><strong className="text-white">Amount:</strong> {formatEther(BigInt(payment.amount))} MON</p>
                      <p className="text-sm text-gray-300"><strong className="text-white">Note:</strong> {payment.note}</p>
                      <p className="text-xs text-gray-500">{new Date(Number(payment.timestamp) * 1000).toLocaleString()}</p>
                    </div>
                  ))}
                </div>
              )}
            </div>
          </div>
        ) : (
          <div className="py-20 text-center">
            <h2 className="mb-4 text-2xl font-semibold text-white">Connect Your Wallet</h2>
            <p className="text-gray-400">Click the Connect Wallet button above to get started</p>
          </div>
        )}
      </div>
    </main>
  )
}

export default function Home() {
  const [mounted, setMounted] = useState(false)

  useEffect(() => {
    setMounted(true)
  }, [])

  if (!mounted) {
    return (
      <main className="min-h-screen bg-[#0a0a0a] p-8">
        <div className="mx-auto max-w-3xl">
          <div className="mb-8 flex items-center justify-between">
            <h1 className="text-3xl font-bold text-purple-500">SocialPay</h1>
            <div className="h-10 w-32 rounded-lg bg-[#1a1a1a]" />
          </div>
          <div className="rounded-lg bg-[#1a1a1a] p-6">
            <p className="text-gray-400">Loading wallet...</p>
          </div>
        </div>
      </main>
    )
  }

  return <WalletContent />
}
