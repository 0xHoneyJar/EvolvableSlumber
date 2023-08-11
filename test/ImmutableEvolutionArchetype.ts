import { expect, assert } from 'chai'
import { getRandomFundedAccount } from "../scripts/functionalHelpers"
import { ImmutableEvolutionContractBuilder } from "../scripts/helpers"

describe('ImmutableEvolutionArchetype', () => {
    it('should have been staked on mint', async () => {
        const nft = await new ImmutableEvolutionContractBuilder()
            .setGeneralConf({ price: 0 })
            .setStakingConf({ automaticStakeTimeOnMint: 1 })
            .build()
        
        const minter = await getRandomFundedAccount()
        await nft.connect(minter).mint(1)
        expect(await nft.getTokenStakedOnMint(1)).true
    })
})
