const mongoose = require('mongoose');

const adminSchema = new mongoose.Schema({
    userId: {
        type: String,
        unique: true,
        required: [true, 'Admin ID is required']
    },
    email: {
        type: String,
        required: [true, 'Email is required'],
        unique: true,
        trim: true,
        lowercase: true
    },
    password: {
        type: String,
        required: [true, 'Password is required']
    },
    name: {
        type: String,
        required: [true, 'Name is required']
    },
    status: {
        type: String,
        enum: ['active', 'inactive'],
        default: 'active'
    },
    role: {
        type: String,
        enum: ['admin'],
        default: 'admin'
    }
}, {
    timestamps: true
});

module.exports = mongoose.model('Admin', adminSchema); 