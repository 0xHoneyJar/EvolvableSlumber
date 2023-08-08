import { ethers } from 'hardhat'
import { EvolutionConfigStruct, GeneralConfigStruct, RewardsConfigStruct, StakingConfigStruct } from '../typechain-types/contracts/ImmutableEvolutionArchetype'

//enum StakingType {
//    NONE, CURRENT, ALIVE, CUMULATIVE
//}

enum StakingType {
    NONE,
    CURRENT,
    ALIVE,
    CUMULATVE
}

const adaptStakingTypeToContract = (t: StakingType) => {
    return ethers.BigNumber.from(t as number)
}

export class ImmutableEvolutionContractBuilder {
    
    // Default contract state (TODO)
    name = 'Test'
    ticker = 'TEST'

    stakingConf: StakingConfigStruct = {
        automaticStakeTimeOnMint: 0,
        automaticStakeTimeOnTx: 0,
        minStakingTime: 0
    }

    evolutionConf: EvolutionConfigStruct = {
        evolutionResolverStrategy: ethers.constants.AddressZero,
        evolutionStakeStrategy: adaptStakingTypeToContract(StakingType.NONE),
    }

    rewardsConf: RewardsConfigStruct = {
        rewardsTakeStrategy: adaptStakingTypeToContract(StakingType.NONE)
    }

    generalConf: GeneralConfigStruct = {
        price: 0,
        baseUri: 'ipfs://example/'
    }

    // Builder setters
    setName(name: string, ticker: string) {
        this.name = name
        this.ticker = ticker
        return this
    }

    setStakingConf(args: Partial<StakingConfigStruct>) {
        this.stakingConf = { ...this.stakingConf, ...args }
        return this
    }

    setEvolutionConf(args: Partial<EvolutionConfigStruct>) {
        this.evolutionConf = { ...this.evolutionConf, ...args }
        return this
    }

    setRewardsConf(args: Partial<EvolutionConfigStruct>) {
        this.rewardsConf = { ...this.rewardsConf, ...args }
        return this
    }

    setGeneralConf(args: Partial<GeneralConfigStruct>) {
        this.generalConf = { ...this.generalConf, ...args }
        return this
    }

    // Final build function
    async build() {
        const EvolutionNftFactory = await ethers.getContractFactory('ImmutableEvolutionArchetype')
        const nft = await EvolutionNftFactory.deploy(this.name, this.ticker)
        await nft.deployed()

        await nft.initialize(
            this.stakingConf,
            this.evolutionConf,
            this.rewardsConf,
            this.generalConf
        )

        return nft
    }
}

