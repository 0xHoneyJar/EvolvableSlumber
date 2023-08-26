import { ethers } from 'hardhat'
import { assert, expect } from 'chai'
import { deployMinimalErc721S } from '../scripts/helpers'
import { getRandomAccount, getRandomFundedAccount, randomAddress } from '../scripts/functionalHelpers'
import * as S from 'fp-ts/string'

describe('ERC721S', () => {
    it('should be able to deploy', async () => {
        await deployMinimalErc721S({ })
    })

    it('should be able to mint', async () => {
        const nft = await deployMinimalErc721S({ automaticStakeTimeOnMint: (60 * 60 * 24) })
        const owner = randomAddress()
        await nft.mintAndStake(owner, 1)
        expect(await nft.balanceOf(owner)).eq(1)
        expect(await nft.ownerOf(1).then(S.toLowerCase)).eq(owner)
    })

    it('should\'t be able to tx if staked on mint', async () => {
        const nft = await deployMinimalErc721S({ automaticStakeTimeOnMint: (60 * 60 * 24) })
        const owner = await getRandomFundedAccount()
        const ownerAlt = randomAddress()
        await nft.mintAndStake(owner.address, 1)

        await expect(nft.connect(owner).transferFrom(owner.address, ownerAlt, 1)).reverted
    })

    it('should be able to tx if not staked on mint', async () => {
        const nft = await deployMinimalErc721S({ automaticStakeTimeOnMint: (60 * 60 * 24) })
        const owner = await getRandomFundedAccount()
        const ownerAlt = randomAddress()
        await nft.mint(owner.address, 1)
        await nft.connect(owner).transferFrom(owner.address, ownerAlt, 1)

        expect(await nft.balanceOf(owner.address)).eq(0)
        expect(await nft.balanceOf(ownerAlt)).eq(1)

        expect(await nft.ownerOf(1).then(S.toLowerCase)).eq(ownerAlt)
    })
})

