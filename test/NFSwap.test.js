const Token = artifacts.require('Token')
const NFSwap = artifacts.require('NFSwap')

require('chai').use(require('chai-as-promised')).should()

function tokensToWei(n) {
    return web3.utils.toWei(n, 'ether')
}

function nTokens(n) {
    let rate = NFSwap.rate
    return web3.utils.toWei(n, 'ether') * rate
}

contract("NFSwap", ([deployer, investor]) => {
    let token, nfSwap

    before(async () => {
      token = await Token.new()
      nfSwap = await NFSwap.new(token.address)
      await token.transfer(nfSwap.address, tokensToWei('1000000'))
    });

    describe("NFSwap deployment", async () => {
        it('contract has a name', async () => {
            const name = await nfSwap.name()
            assert.equal(name, 'NoFillSwap Instance Exchange')
        })
    });

    describe("Token deployment", async () => {
         it('contract has a name', async () => {
            const name = await token.name()
            assert.equal(name, 'DApp Token')
         });

         it('contract has tokens', async () => {
                 let balance = await token.balanceOf(nfSwap.address)
                 assert.equal(balance.toString(), tokensToWei('1000000'))
          });
    });

    describe("buyTokens", async () => {
        let result

        before(async () => {
            result = await nfSwap.buyTokens({ from: investor, value: tokensToWei('1')})
            //result = await nfSwap.buyTokens(tokensToWei('1'), investor)
        })

        it("Allows user to instantly purchase tokens from ethSwap for a fixed price", async () => {
            let investorBal = await token.balanceOf(investor)
            assert.equal(investorBal.toString(), tokensToWei('100'))

            // Confirm NFSwap balanace after purchace
            let nfSwapBal
            nfSwapBal = await token.balanceOf(nfSwap.address)
            assert.equal(nfSwapBal.toString(), tokensToWei('999900'))
            nfSwapBal = await web3.eth.getBalance(nfSwap.address)
            assert.equal(nfSwapBal.toString(), web3.utils.toWei('1','Ether'))

            const event = result.logs[0].args
            assert.equal(event.account, investor)
            assert.equal(event.token, token.address)
            assert.equal(event.amount.toString(), tokensToWei('100').toString())
            assert.equal(event.rate.toString(), '100')
        })
    })

    //describe(*)
    describe("sellTokens", async () => {
            let result

            before(async () => {
                // Investor must approve the tokens to be sold before the purchase
                await token.approve(nfSwap.address, tokensToWei('100'), {from: investor})
                // Investor sells the tokens for ETH
                result = await nfSwap.sellTokens(tokensToWei('100'), {from: investor})
            })

            it("Allows user to instantly sell tokens to ethSwap for a fixed price", async () => {
                let investorBal = await token.balanceOf(investor)
                assert.equal(investorBal.toString(), tokensToWei('0'))

                let nfSwapBal
                nfSwapBal = await token.balanceOf(nfSwap.address)
                assert.equal(nfSwapBal.toString(), tokensToWei('1000000'))
                nfSwapBal = await web3.eth.getBalance(nfSwap.address)
                assert.equal(nfSwapBal.toString(), web3.utils.toWei('0','Ether'))

                const event = result.logs[0].args
                assert.equal(event.account, investor)
                assert.equal(event.token, token.address)
                assert.equal(event.amount.toString(), tokensToWei('100').toString())
                assert.equal(event.rate.toString(), '100')

                // FAILURE : investor can't sell more tokens than they already have
                await nfSwap.sellTokens(tokensToWei('500'), {from: investor}).should.be.rejected;
            })
        })

})