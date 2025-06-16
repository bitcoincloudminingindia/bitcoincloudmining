const mongoose = require('mongoose');

const transactionSchema = new mongoose.Schema({
    transactionId: {
        type: String,
        required: true,
        unique: true
    },
    userId: {
        type: String,
        required: true,
        ref: 'User'
    },
    type: {
        type: String,
        enum: ['deposit', 'withdrawal', 'reward', 'referral', 'mining', 'tap'],
        required: true
    }, amount: {
        type: String,
        required: true
    },
    netAmount: {
        type: String,
        required: true
    },
    status: {
        type: String,
        enum: ['pending', 'completed', 'failed', 'cancelled'],
        default: 'pending'
    },
    currency: {
        type: String,
        required: true,
        default: 'BTC'
    },
    description: {
        type: String
    },
    destination: {
        type: String,
        default: 'Wallet'
    },
    details: {
        type: mongoose.Schema.Types.Mixed,
        default: {}
    },
    timestamp: {
        type: Date,
        default: Date.now
    },
    metadata: {
        type: mongoose.Schema.Types.Mixed
    },
    createdAt: {
        type: Date,
        default: Date.now
    },
    updatedAt: {
        type: Date,
        default: Date.now
    }
});

// Pre-save middleware to format amounts
transactionSchema.pre('save', function (next) {
    const { formatBTC } = require('../utils/format');

    try {
        // Format amount
        if (this.amount) {
            const amt = typeof this.amount === 'object' ? this.amount.toString() : this.amount;
            this.amount = formatBTC(amt);
        }

        // Format netAmount
        if (this.netAmount) {
            const netAmt = typeof this.netAmount === 'object' ? this.netAmount.toString() : this.netAmount;
            this.netAmount = formatBTC(netAmt);
        }

        // Format balance details
        if (this.details) {
            if (this.details.balanceBefore) {
                const before = typeof this.details.balanceBefore === 'object' ?
                    this.details.balanceBefore.toString() : this.details.balanceBefore;
                this.details.balanceBefore = formatBTC(before);
            }
            if (this.details.balanceAfter) {
                const after = typeof this.details.balanceAfter === 'object' ?
                    this.details.balanceAfter.toString() : this.details.balanceAfter;
                this.details.balanceAfter = formatBTC(after);
            }
            if (this.details.originalAmount) {
                const origAmt = typeof this.details.originalAmount === 'object' ?
                    this.details.originalAmount.toString() : this.details.originalAmount;
                this.details.originalAmount = formatBTC(origAmt);
            }
            if (this.details.originalNetAmount) {
                const origNetAmt = typeof this.details.originalNetAmount === 'object' ?
                    this.details.originalNetAmount.toString() : this.details.originalNetAmount;
                this.details.originalNetAmount = formatBTC(origNetAmt);
            }
        }

        next();
    } catch (error) {
        console.error('Error formatting transaction amounts:', error);
        next(error);
    }
});

transactionSchema.pre('save', function (next) {
    this.updatedAt = Date.now();
    next();
});

const Transaction = mongoose.model('Transaction', transactionSchema);

module.exports = Transaction;
