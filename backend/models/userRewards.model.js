const mongoose = require('mongoose');

const userRewardsSchema = new mongoose.Schema({
    user_id: {
        type: mongoose.Schema.Types.ObjectId,
        ref: 'User',
        required: true
    },
    userId: {
        type: String,
        ref: 'User',
        required: true,
        unique: true
    },
    total_rewards: {
        type: Number,
        default: 0,
        min: 0
    },
    last_updated: {
        type: Date,
        default: Date.now
    }
}, {
    timestamps: true
});

// Pre-save middleware to ensure userId is set
userRewardsSchema.pre('save', function (next) {
    // If we have both IDs, proceed
    if (this.user_id && this.userId) {
        return next();
    }

    // Skip validation if neither ID is set
    if (!this.user_id && !this.userId) {
        return next(new Error('Either user_id or userId must be provided'));
    }

    next();
});

module.exports = mongoose.model('UserRewards', userRewardsSchema);