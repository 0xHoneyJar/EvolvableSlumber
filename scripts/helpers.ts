import { ethers } from 'hardhat'
import { EvolutionConfigStruct, GeneralConfigStruct, RewardsConfigStruct, StakingConfigStruct } from '../typechain-types/contracts/ImmutableEvolutionArchetype'

//enum StakingType {
//    NONE, CURRENT, ALIVE, CUMULATIVE
//}

type StakingType = 'NONE'
                 | 'CURRENT'
                 | 'ALIVE'
                 | 'CUMULATVE'

const adaptStakingTypeToContract = (t: StakingType) => {
    return ethers.BigNumber.from(t)
}

export class ImmutableEvolutionArchetypeBuilder {
    
    // Default contract state
    name = 'Test'
    ticker = 'TEST'

    stakingConf: StakingConfigStruct = {
        automaticStakeTimeOnMint: 0,
        automaticStakeTimeOnTx: 0,
        minStakingTime: 0
    }

    evolutionConf: EvolutionConfigStruct = {
        evolutionResolverStrategy: ethers.constants.AddressZero,
        evolutionStakeStrategy: adaptStakingTypeToContract('NONE'),
    }

    rewardsConf: RewardsConfigStruct = {
        rewardsTakeStrategy: adaptStakingTypeToContract('NONE')
    }

    generalConf: GeneralConfigStruct = {
        price: 0,
        baseUri: 'ipfs://example/'
    }

    // Builder setters
    setStakingConf({
        automaticStakeTimeOnMint,
        automaticStakeTimeOnTx,
        minStakingTime
    }: Partial<StakingConfigStruct>) {
        if (automaticStakeTimeOnTx)
            this.stakingConf.automaticStakeTimeOnTx = automaticStakeTimeOnTx
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

