const mongoose = require('mongoose');

const dailyRewardSchema = new mongoose.Schema({
    userId: {
        type: mongoose.Schema.Types.ObjectId,
        ref: 'User',
        required: true,
        unique: true
    },
    lastClaimDate: {
        type: Date,
        default: null
    },
    streakCount: {
        type: Number,
        default: 0
    },
    lastStreakReset: {
        type: Date,
        default: null
    }
}, {
    timestamps: true
});

// Add method to check if user can claim daily reward
dailyRewardSchema.methods.canClaim = function() {
    if (!this.lastClaimDate) return true;
    
    const now = new Date();
    const lastClaim = new Date(this.lastClaimDate);
    
    // Check if 24 hours have passed since last claim
    const hoursSinceLastClaim = (now - lastClaim) / (1000 * 60 * 60);
    return hoursSinceLastClaim >= 24;
};

// Add method to update streak
dailyRewardSchema.methods.updateStreak = function() {
    const now = new Date();
    const lastClaim = new Date(this.lastClaimDate);
    
    // Check if last claim was within 48 hours (to maintain streak)
    const hoursSinceLastClaim = (now - lastClaim) / (1000 * 60 * 60);
    
    if (hoursSinceLastClaim <= 48) {
        this.streakCount += 1;
    } else {
        this.streakCount = 1;
    }
    
    this.lastClaimDate = now;
    return this.save();
};

module.exports = mongoose.model('DailyReward', dailyRewardSchema); 