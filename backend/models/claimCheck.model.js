const mongoose = require('mongoose');

const claimCheckSchema = new mongoose.Schema({
    userId: {
        type: mongoose.Schema.Types.ObjectId,
        ref: 'User',
        required: true
    },
    transactionId: {
        type: String,
        required: true,
        unique: true
    },
    originalTransactionId: {
        type: String,
        required: true
    },
    amount: {
        type: String,
        required: true,
        get: function(val) {
            const num = parseFloat(val);
            if (isNaN(num)) return '0.000000000000000000';
            return num.toFixed(18);
        },
        set: function(val) {
            const num = parseFloat(val);
            if (isNaN(num)) return '0.000000000000000000';
            return num.toFixed(18);
        }
    },
    status: {
        type: String,
        enum: ['pending', 'completed', 'rejected'],
        default: 'pending'
    },
    type: {
        type: String,
        enum: ['claim', 'rejected_to_completed'],
        required: true
    },
    timestamp: {
        type: Date,
        default: Date.now
    },
    description: String,
    details: {
        type: Map,
        of: mongoose.Schema.Types.Mixed
    }
}, {
    timestamps: true,
    toJSON: { getters: true },
    toObject: { getters: true }
});

// Create indexes for faster queries
claimCheckSchema.index({ userId: 1, transactionId: 1 });
claimCheckSchema.index({ originalTransactionId: 1 });

module.exports = mongoose.model('ClaimCheck', claimCheckSchema); 