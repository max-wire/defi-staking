import { useCallback, useEffect, useState } from "react";
import { Contract, formatUnits, parseUnits } from "ethers";

import { CONTRACTS } from "../contracts/config";

import stakeTokenAbi from "../contracts/abis/StakeToken.json";
import rewardTokenAbi from "../contracts/abis/RewardToken.json";
import stakingVaultAbi from "../contracts/abis/StakingVault.json";

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

  const getContracts = useCallback(async () => {
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

  const refreshData = useCallback(async () => {
    if (!provider || !account) return;

    if (
      !CONTRACTS.stakeToken ||
      !CONTRACTS.rewardToken ||
      !CONTRACTS.stakingVault
    ) {
      return;
    }

    setError(null);

    try {
      const contracts = await getContracts();

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
      setError(
        err?.shortMessage ||
          err?.message ||
          "Failed to load staking data.",
      );
    }
  }, [provider, account, getContracts]);

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

  const approveStake = useCallback(
    async (amount) => {
      setLoading(true);
      setError(null);

      try {
        const contracts = await getContracts();

        if (!contracts) {
          throw new Error("Wallet provider is not available.");
        }

        const parsedAmount = parseUnits(amount, 18);

        const tx = await contracts.stakeToken.approve(
          CONTRACTS.stakingVault,
          parsedAmount,
        );

        await tx.wait();
        await refreshData();

        return tx;
      } catch (err) {
        setError(
          err?.shortMessage || err?.message || "Approval failed.",
        );
        throw err;
      } finally {
        setLoading(false);
      }
    },
    [getContracts, refreshData],
  );

  const stake = useCallback(
    async (amount) => {
      setLoading(true);
      setError(null);

      try {
        const contracts = await getContracts();

        if (!contracts) {
          throw new Error("Wallet provider is not available.");
        }

        const parsedAmount = parseUnits(amount, 18);

        const tx = await contracts.stakingVault.stake(parsedAmount);

        await tx.wait();
        await refreshData();

        return tx;
      } catch (err) {
        setError(
          err?.shortMessage || err?.message || "Staking failed.",
        );
        throw err;
      } finally {
        setLoading(false);
      }
    },
    [getContracts, refreshData],
  );

  const withdraw = useCallback(
    async (amount) => {
      setLoading(true);
      setError(null);

      try {
        const contracts = await getContracts();

        if (!contracts) {
          throw new Error("Wallet provider is not available.");
        }

        const parsedAmount = parseUnits(amount, 18);

        const tx = await contracts.stakingVault.withdraw(parsedAmount);

        await tx.wait();
        await refreshData();

        return tx;
      } catch (err) {
        setError(
          err?.shortMessage || err?.message || "Withdrawal failed.",
        );
        throw err;
      } finally {
        setLoading(false);
      }
    },
    [getContracts, refreshData],
  );

  const claimRewards = useCallback(async () => {
    setLoading(true);
    setError(null);

    try {
      const contracts = await getContracts();

      if (!contracts) {
        throw new Error("Wallet provider is not available.");
      }

      const tx = await contracts.stakingVault.claimRewards();

      await tx.wait();
      await refreshData();

      return tx;
    } catch (err) {
      setError(
        err?.shortMessage ||
          err?.message ||
          "Reward claim failed.",
      );
      throw err;
    } finally {
      setLoading(false);
    }
  }, [getContracts, refreshData]);

  const exit = useCallback(async () => {
    setLoading(true);
    setError(null);

    try {
      const contracts = await getContracts();

      if (!contracts) {
        throw new Error("Wallet provider is not available.");
      }

      const tx = await contracts.stakingVault.exit();

      await tx.wait();
      await refreshData();

      return tx;
    } catch (err) {
      setError(
        err?.shortMessage || err?.message || "Exit failed.",
      );
      throw err;
    } finally {
      setLoading(false);
    }
  }, [getContracts, refreshData]);

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
    approveStake,
    stake,
    withdraw,
    claimRewards,
    exit,
  };
}