import { getChecksumAddress, uint256 } from 'starknet'

import { FACTORY_ADDRESSES } from '../constants'
import { LIQUIDITY_LOCK_FOREVER_TIMESTAMP, LiquidityType, Selector } from '../constants/misc'
import { EkuboLiquidity, JediswapLiquidity, LaunchedLiquidity, MemecoinLaunchData } from '../types/memecoin'
import { multiCallContract } from '../utils/contract'
import { FactoryConfig } from './interface'

type MemecoinData = {
  address: string
  name: string
  symbol: string
  owner: string
  decimals: number
}

// eslint-disable-next-line import/no-unused-modules
export class Memecoin {
  public config: FactoryConfig

  public address: string
  public name: string
  public symbol: string
  public owner: string
  public decimals: number

  constructor(config: FactoryConfig, data: MemecoinData) {
    this.config = config

    this.address = data.address
    this.name = data.name
    this.symbol = data.symbol
    this.owner = data.owner
    this.decimals = data.decimals
  }

  /**
   * Get the total supply of the memecoin
   * @returns Total supply of the memecoin
   */
  public async getTotalSupply(): Promise<bigint> {
    const { result } = await this.config.provider.callContract({
      contractAddress: this.address,
      entrypoint: Selector.TOTAL_SUPPLY,
    })

    return uint256.uint256ToBN({ low: result[0], high: result[1] })
  }

  /**
   * Get launch information of the memecoin
   * @returns Launch information of the memecoin
   */
  public async getLaunch(): Promise<MemecoinLaunchData> {
    const result = await multiCallContract(this.config.provider, this.config.chainId, [
      {
        to: this.address,
        selector: Selector.GET_TEAM_ALLOCATION,
      },
      {
        to: this.address,
        selector: Selector.LAUNCHED_AT_BLOCK_NUMBER,
      },
    ])

    const [teamAllocation, [launchBlockNumber]] = result

    const liquidity = await this.getLiquidity()

    if (liquidity === undefined) {
      return {
        isLaunched: false,
      }
    }

    return {
      isLaunched: true,
      teamAllocation: uint256.uint256ToBN({ low: teamAllocation[0], high: teamAllocation[1] }),
      blockNumber: Number(launchBlockNumber),
      liquidity,
    }
  }

  /**
   * Get the launched liquidity of the memecoin
   * @returns Launched liquidity of the memecoin. Returns undefined if the memecoin is not launched.
   */
  public async getLiquidity(): Promise<LaunchedLiquidity | undefined> {
    const result = await multiCallContract(this.config.provider, this.config.chainId, [
      {
        to: this.address,
        selector: Selector.IS_LAUNCHED,
      },
      {
        to: FACTORY_ADDRESSES[this.config.chainId],
        selector: Selector.LOCKED_LIQUIDITY,
        calldata: [this.address],
      },
      {
        to: this.address,
        selector: Selector.LAUNCHED_WITH_LIQUIDITY_PARAMETERS,
      },
    ])

    const [[launched], [dontHaveLiq, lockManager, liqTypeIndex, ekuboId], launchParams] = result

    const liquidityType = Object.values(LiquidityType)[+liqTypeIndex] as LiquidityType

    const isLaunched = !!+launched && !+dontHaveLiq && !+launchParams[0] && liquidityType

    if (!isLaunched) return undefined

    switch (liquidityType) {
      case LiquidityType.STARKDEFI_ERC20:
      case LiquidityType.JEDISWAP_ERC20: {
        const liquidity = {
          type: liquidityType,
          lockManager,
          lockPosition: launchParams[5],
          quoteToken: getChecksumAddress(launchParams[2]),
          quoteAmount: uint256.uint256ToBN({ low: launchParams[3], high: launchParams[4] }),
        } satisfies Partial<JediswapLiquidity>

        return {
          ...liquidity,
          ...(await this.getJediswapLiquidityLockPosition(liquidity)),
        }
      }

      case LiquidityType.EKUBO_NFT: {
        const liquidity = {
          type: liquidityType,
          lockManager,
          ekuboId,
          quoteToken: getChecksumAddress(launchParams[7]),
          startingTick: +launchParams[4] * (+launchParams[5] ? -1 : 1), // mag * sign
        } satisfies Partial<EkuboLiquidity>

        return {
          ...liquidity,
          ...(await this.getEkuboLiquidityLockPosition(liquidity)),
        }
      }
    }
  }

  private async getJediswapLiquidityLockPosition(liquidity: Pick<JediswapLiquidity, 'lockManager' | 'lockPosition'>) {
    const { result } = await this.config.provider.callContract({
      contractAddress: liquidity.lockManager,
      entrypoint: Selector.GET_LOCK_DETAILS,
      calldata: [liquidity.lockPosition],
    })

    return {
      unlockTime: +result[4],
      owner: getChecksumAddress(result[3]),
    } satisfies Partial<JediswapLiquidity>
  }

  private async getEkuboLiquidityLockPosition(liquidity: Pick<EkuboLiquidity, 'lockManager' | 'ekuboId'>) {
    const { result } = await this.config.provider.callContract({
      contractAddress: liquidity.lockManager,
      entrypoint: Selector.LIQUIDITY_POSITION_DETAILS,
      calldata: [liquidity.ekuboId],
    })

    return {
      unlockTime: LIQUIDITY_LOCK_FOREVER_TIMESTAMP,
      owner: getChecksumAddress(result[0]),
      poolKey: {
        token0: getChecksumAddress(result[2]),
        token1: getChecksumAddress(result[3]),
        fee: result[4],
        tickSpacing: result[5],
        extension: result[6],
      },
      bounds: {
        lower: {
          mag: result[7],
          sign: result[8],
        },
        upper: {
          mag: result[9],
          sign: result[10],
        },
      },
    } satisfies Partial<EkuboLiquidity>
  }
}
