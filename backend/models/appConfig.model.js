const mongoose = require('mongoose');

const appConfigSchema = new mongoose.Schema({
    referralDailyPercent: {
        type: Number,
        default: 1.0, // 1% by default
        min: 0,
        max: 100
    },
    referralEarningDays: {
        type: Number,
        default: 30, // 30 days by default
        min: 1,
        max: 365
    },
    updatedAt: {
        type: Date,
        default: Date.now
    }
});

const AppConfig = mongoose.model('AppConfig', appConfigSchema);
module.exports = AppConfig; 