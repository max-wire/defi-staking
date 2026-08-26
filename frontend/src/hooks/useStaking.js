import { useCallback, useEffect, useState } from "react";
import { Contract, formatUnits, parseUnits } from "ethers";

import { CONTRACTS } from "../contracts/config";

import stakeTokenAbi from "../contracts/abis/StakeToken.json";
import rewardTokenAbi from "../contracts/abis/RewardToken.json";
import stakingVaultAbi from "../contracts/abis/StakingVault.json";

function getErrorMessage(err, fallback) {
  if (err?.code === 4001) {
    return null;
  }

  return err?.shortMessage || err?.reason || err?.message || fallback;
}

export function useStaking(provider, account) {
  const [stakeBalance, setStakeBalance] = useState("0");
  const [rewardBalance, setRewardBalance] = useState("0");
  const [stakedAmount, setStakedAmount] = useState("0");
  const [earnedRewards, setEarnedRewards] = useState("0");
  const [totalStaked, setTotalStaked] = useState("0");
  const [rewardRate, setRewardRate] = useState("0");
  const [rewardRemaining, setRewardRemaining] = useState("0");

  const [loading, setLoading] = useState(false);
  const [error, setError] = useState(null);

  /*
   * READ CONTRACTS
   *
   * These use the provider because they only perform
   * read-only calls.
   */
  const getReadContracts = useCallback(() => {
    if (!provider) return null;

    return {
      stakeToken: new Contract(
        CONTRACTS.stakeToken,
        stakeTokenAbi.abi || stakeTokenAbi,
        provider,
      ),

      rewardToken: new Contract(
        CONTRACTS.rewardToken,
        rewardTokenAbi.abi || rewardTokenAbi,
        provider,
      ),

      stakingVault: new Contract(
        CONTRACTS.stakingVault,
        stakingVaultAbi.abi || stakingVaultAbi,
        provider,
      ),
    };
  }, [provider]);

  /*
   * WRITE CONTRACTS
   *
   * These use the connected wallet signer.
   */
  const getWriteContracts = useCallback(async () => {
    if (!provider) return null;

    const signer = await provider.getSigner();

    return {
      stakeToken: new Contract(
        CONTRACTS.stakeToken,
        stakeTokenAbi.abi || stakeTokenAbi,
        signer,
      ),

      rewardToken: new Contract(
        CONTRACTS.rewardToken,
        rewardTokenAbi.abi || rewardTokenAbi,
        signer,
      ),

      stakingVault: new Contract(
        CONTRACTS.stakingVault,
        stakingVaultAbi.abi || stakingVaultAbi,
        signer,
      ),
    };
  }, [provider]);

  /*
   * ALLOWANCE
   */
  const getAllowance = useCallback(async () => {
    if (!account) return 0n;

    const contracts = getReadContracts();

    if (!contracts) {
      throw new Error("Wallet provider is not available.");
    }

    return contracts.stakeToken.allowance(account, CONTRACTS.stakingVault);
  }, [account, getReadContracts]);

  /*
   * REFRESH DATA
   */
  const refreshData = useCallback(async () => {
    if (!provider || !account) return;

    if (
      !CONTRACTS.stakeToken ||
      !CONTRACTS.rewardToken ||
      !CONTRACTS.stakingVault
    ) {
      return;
    }

    try {
      const contracts = getReadContracts();

      if (!contracts) return;

      const [
        stakeBalanceRaw,
        rewardBalanceRaw,
        userInfo,
        earnedRaw,
        totalStakedRaw,
        rewardRateRaw,
        rewardRemainingRaw,
      ] = await Promise.all([
        contracts.stakeToken.balanceOf(account),
        contracts.rewardToken.balanceOf(account),
        contracts.stakingVault.getUserInfo(account),
        contracts.stakingVault.earned(account),
        contracts.stakingVault.totalStaked(),
        contracts.stakingVault.rewardRate(),
        contracts.stakingVault.rewardRemaining(),
      ]);

      setStakeBalance(formatUnits(stakeBalanceRaw, 18));
      setRewardBalance(formatUnits(rewardBalanceRaw, 18));
      setStakedAmount(formatUnits(userInfo[0], 18));
      setEarnedRewards(formatUnits(earnedRaw, 18));
      setTotalStaked(formatUnits(totalStakedRaw, 18));
      setRewardRate(formatUnits(rewardRateRaw, 18));
      setRewardRemaining(formatUnits(rewardRemainingRaw, 18));
    } catch (err) {
      console.error("Failed to refresh staking data:", err);

      const message = getErrorMessage(err, "Failed to load staking data.");

      if (message) {
        setError(message);
      }
    }
  }, [provider, account, getReadContracts]);

  /*
   * AUTO REFRESH
   */
  useEffect(() => {
    if (!provider || !account) return;

    let mounted = true;

    const initialRefresh = async () => {
      if (!mounted) return;
      await refreshData();
    };

    initialRefresh();

    const handleBlock = async () => {
      if (!mounted) return;
      await refreshData();
    };

    provider.on("block", handleBlock);

    return () => {
      mounted = false;
      provider.off("block", handleBlock);
    };
  }, [provider, account, refreshData]);

  /*
   * APPROVE
   *
   * Checks:
   * 1. User has sufficient STAKE balance.
   * 2. Existing allowance is sufficient.
   *
   * Returns false if approval was already sufficient.
   * Returns true if an approval transaction was required.
   */
  const approveStake = useCallback(
    async (amount) => {
      if (!account) {
        throw new Error("Wallet is not connected.");
      }

      if (!amount || Number(amount) <= 0) {
        throw new Error("Enter a valid staking amount.");
      }

      const contracts = await getWriteContracts();

      if (!contracts) {
        throw new Error("Wallet provider is not available.");
      }

      const parsedAmount = parseUnits(amount, 18);

      const balance = await contracts.stakeToken.balanceOf(account);

      if (balance < parsedAmount) {
        throw new Error(
          `Insufficient STAKE balance. You have ${formatUnits(
            balance,
            18,
          )} STAKE.`,
        );
      }

      const allowance = await contracts.stakeToken.allowance(
        account,
        CONTRACTS.stakingVault,
      );

      if (allowance >= parsedAmount) {
        return false;
      }

      const tx = await contracts.stakeToken.approve(
        CONTRACTS.stakingVault,
        parsedAmount,
      );

      await tx.wait();

      return true;
    },
    [account, getWriteContracts],
  );

  /*
   * STAKE
   */
  const stake = useCallback(
    async (amount) => {
      const contracts = await getWriteContracts();

      if (!contracts) {
        throw new Error("Wallet provider is not available.");
      }

      const parsedAmount = parseUnits(amount, 18);

      const tx = await contracts.stakingVault.stake(parsedAmount);

      await tx.wait();

      return tx;
    },
    [getWriteContracts],
  );

  /*
   * APPROVE + STAKE
   *
   * This is the main action exposed to the UI.
   */
  const stakeWithApproval = useCallback(
    async (amount) => {
      setLoading(true);
      setError(null);

      try {
        await approveStake(amount);
        const tx = await stake(amount);

        await refreshData();

        return tx;
      } catch (err) {
        const message = getErrorMessage(err, "Staking failed.");

        if (message) {
          setError(message);
        }

        throw err;
      } finally {
        setLoading(false);
      }
    },
    [approveStake, stake, refreshData],
  );

  /*
   * WITHDRAW
   */
  const withdraw = useCallback(
    async (amount) => {
      setLoading(true);
      setError(null);

      try {
        const contracts = await getWriteContracts();

        if (!contracts) {
          throw new Error("Wallet provider is not available.");
        }

        const parsedAmount = parseUnits(amount, 18);

        const tx = await contracts.stakingVault.withdraw(parsedAmount);

        await tx.wait();

        await refreshData();

        return tx;
      } catch (err) {
        const message = getErrorMessage(err, "Withdrawal failed.");

        if (message) {
          setError(message);
        }

        throw err;
      } finally {
        setLoading(false);
      }
    },
    [getWriteContracts, refreshData],
  );

  /*
   * CLAIM REWARDS
   */
  const claimRewards = useCallback(async () => {
    setLoading(true);
    setError(null);

    try {
      const contracts = await getWriteContracts();

      if (!contracts) {
        throw new Error("Wallet provider is not available.");
      }

      const tx = await contracts.stakingVault.claimRewards();

      await tx.wait();

      await refreshData();

      return tx;
    } catch (err) {
      const message = getErrorMessage(err, "Reward claim failed.");

      if (message) {
        setError(message);
      }

      throw err;
    } finally {
      setLoading(false);
    }
  }, [getWriteContracts, refreshData]);

  /*
   * EXIT
   */
  const exit = useCallback(async () => {
    setLoading(true);
    setError(null);

    try {
      const contracts = await getWriteContracts();

      if (!contracts) {
        throw new Error("Wallet provider is not available.");
      }

      const tx = await contracts.stakingVault.exit();

      await tx.wait();

      await refreshData();

      return tx;
    } catch (err) {
      const message = getErrorMessage(err, "Exit failed.");

      if (message) {
        setError(message);
      }

      throw err;
    } finally {
      setLoading(false);
    }
  }, [getWriteContracts, refreshData]);

  return {
    stakeBalance,
    rewardBalance,
    stakedAmount,
    earnedRewards,
    totalStaked,
    rewardRate,
    rewardRemaining,

    loading,
    error,

    refreshData,
    getAllowance,

    approveStake,
    stake,
    stakeWithApproval,

    withdraw,
    claimRewards,
    exit,
  };
}
