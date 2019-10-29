from time import sleep, time
from logging import debug

from tools.test_case import TestCase
from tools.test_pool import test_pool


class SendERC20ToSchain(TestCase):
    erc20 = None
    # index of token in lock_and_data_for_schain_erc20.sol
    index = 1

    def __init__(self, config):
        super().__init__('Send ERC20 to schain', config)

    def _prepare(self):
        self.erc20 = self.blockchain.deploy_erc20_on_mainnet(self.config.mainnet_key, 'D2-Token', 'D2', 100)

        address = self.blockchain.key_to_address(self.config.mainnet_key)
        mint_txn = self.erc20.functions.mint(address, 1)\
            .buildTransaction({
                'gas': 8000000,
                'nonce': self.blockchain.get_transactions_count_on_mainnet(address)})

        sleep(7)
        signed_txn = self.blockchain.web3_mainnet.eth.account.signTransaction(mint_txn,
                                                                              private_key=self.config.mainnet_key)
        sleep(7)
        self.blockchain.web3_mainnet.eth.sendRawTransaction(signed_txn.rawTransaction)
        sleep(10)

    def _execute(self):
        amount = 1
        self.agent.transfer_erc20_from_mainnet_to_schain(self.erc20,
                                                         self.config.mainnet_key,
                                                         self.config.schain_key,
                                                         amount,
                                                         self.index,
                                                         self.timeout)
        sleep(7)

        erc20 = self.blockchain.get_erc20_on_schain(self.index)
        destination_address = self.blockchain.key_to_address(self.config.schain_key)
        balance = erc20.functions.balanceOf(destination_address).call()
        if balance == amount:
            self._mark_passed()

test_pool.register_test(SendERC20ToSchain)
