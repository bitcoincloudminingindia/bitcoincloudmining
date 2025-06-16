const BigNumber = require('bignumber.js');
const { formatBTC } = require('./format');
const logger = require('./logger');

// Configure BigNumber
BigNumber.config({
    DECIMAL_PLACES: 18,
    ROUNDING_MODE: BigNumber.ROUND_DOWN,
    FORMAT: {
        decimalSeparator: '.',
        groupSeparator: '',
        groupSize: 0,
        secondaryGroupSize: 0,
        fractionGroupSeparator: '',
        fractionGroupSize: 0
    }
});

/**
 * Calculate balance from transactions
 */
const calculateBalanceFromTransactions = (transactions) => {
    try {
        let balance = new BigNumber('0.000000000000000000');
        const processedTxIds = new Set();
        const balanceHistory = [];

        // Sort transactions by timestamp
        const sortedTransactions = [...transactions]
            .filter(tx => tx.status === 'completed')
            .sort((a, b) => new Date(a.timestamp) - new Date(b.timestamp));

        // Process each transaction
        for (const tx of sortedTransactions) {
            try {
                // Skip if already processed
                if (processedTxIds.has(tx.transactionId)) {
                    logger.info('Skipping duplicate transaction:', {
                        transactionId: tx.transactionId
                    });
                    continue;
                }

                // Get the amount from transaction
                let amount;
                if (tx.details?.originalNetAmount) {
                    amount = new BigNumber(tx.details.originalNetAmount);
                } else if (tx.netAmount) {
                    amount = new BigNumber(tx.netAmount);
                } else if (tx.amount) {
                    amount = new BigNumber(tx.amount);
                } else {
                    amount = new BigNumber(0);
                }

                const prevBalance = balance;

                // Update balance based on transaction type
                if (['deposit', 'reward', 'mining', 'earning', 'referral',
                    'daily_reward', 'gaming_reward', 'claim', 'tap'].includes(tx.type)) {
                        balance = balance.plus(amount);
                } else if (['withdrawal', 'penalty'].includes(tx.type)) {
                    // Check if withdrawal amount is too small
                    if (amount.isLessThan(new BigNumber('0.000000000000001'))) {
                        logger.warn('Transaction amount too small:', {
                            transactionId: tx.transactionId,
                            amount: amount.toString()
                        });
                        continue;
                    }
                    // Check for sufficient balance
                    if (balance.isLessThan(amount)) {
                        logger.error('Insufficient balance for withdrawal:', {
                            transactionId: tx.transactionId,
                            balance: balance.toString(),
                            amount: amount.toString()
                        });
                        continue;
                    }
                    balance = balance.minus(amount);
                }

                // Update transaction details
                tx.details = tx.details || {}; const formattedPrevBalance = formatBTC(prevBalance.toString());
                const formattedNewBalance = formatBTC(balance.toString());

                tx.details.balanceBefore = formattedPrevBalance;
                tx.details.balanceAfter = formattedNewBalance;

                // Record balance history
                balanceHistory.push({
                    transactionId: tx.transactionId,
                    timestamp: tx.timestamp,
                    type: tx.type,
                    amount: formatBTC(amount.toString()),
                    balanceBefore: formattedPrevBalance,
                    balanceAfter: formattedNewBalance
                });

                // Mark as processed
                processedTxIds.add(tx.transactionId);

                logger.info('Transaction processed:', {
                    transactionId: tx.transactionId,
                    type: tx.type,
                    amount: formatBTC(amount.toString()),
                    balanceBefore: formattedPrevBalance,
                    balanceAfter: formattedNewBalance,
                    processedTxCount: processedTxIds.size
                });
            } catch (error) {
                logger.error('Error processing transaction:', {
                    error,
                    transactionId: tx.transactionId,
                    type: tx.type,
                    amount: tx.amount
                });
            }
        } const finalBalance = formatBTC(balance.toString());
        return {
            balance: finalBalance,
            history: balanceHistory,
            processedTransactions: Array.from(processedTxIds)
        };
    } catch (error) {
        logger.error('Error calculating balance:', error);
        return {
            balance: '0.000000000000000000',
            history: [],
            processedTransactions: []
        };
    }
};

/**
 * Update wallet balance from transactions
 */
const updateWalletBalance = async (wallet, transactions) => {
    const session = await wallet.db.startSession();
    session.startTransaction();

    try {
        // Get current balance for comparison
        const oldBalance = wallet.balance || '0.000000000000000000';

        // Calculate new balance from completed transactions only
        const newBalance = calculateBalanceFromTransactions(transactions);

        // Validate the new balance
        if (!/^\d+\.\d{18}$/.test(newBalance)) {
            throw new Error(`Invalid balance format: ${newBalance}`);
        }

        // Only update if balance has changed
        if (newBalance !== oldBalance) {
            // Calculate the difference
            const balanceDiff = new BigNumber(newBalance).minus(oldBalance);

            // Update wallet atomically
            const updatedWallet = await wallet.constructor.findOneAndUpdate(
                { _id: wallet._id },
                {
                    $set: {
                        balance: newBalance,
                        lastUpdated: new Date()
                    },
                    $push: {
                        balanceHistory: {
                            amount: formatBTC(balanceDiff.toString()),
                            type: 'balance_sync',
                            timestamp: new Date(),
                            oldBalance: formatBTC(oldBalance),
                            newBalance: formatBTC(newBalance)
                        }
                    }
                },
                { new: true, session }
            );

            if (!updatedWallet) {
                throw new Error('Failed to update wallet balance');
            }

            // Update the instance
            Object.assign(wallet, updatedWallet);

            logger.info('Wallet balance updated successfully:', {
                userId: wallet.userId,
                oldBalance: formatBTC(oldBalance),
                newBalance: formatBTC(newBalance),
                difference: formatBTC(balanceDiff.toString()),
                type: 'balance_sync'
            });
        }

        await session.commitTransaction();
        return newBalance;

    } catch (error) {
        await session.abortTransaction();
        logger.error('Error updating wallet balance:', error);
        return oldBalance;
    } finally {
        session.endSession();
    }
};

module.exports = {
    calculateBalanceFromTransactions,
    updateWalletBalance
};
