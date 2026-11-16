
const mongoose = require('mongoose');

const taskSchema = new mongoose.Schema({
    title: {
        type: String,
        required: true,
        trim: true
    },

    description: {
        type: String,
        default: ''
    },

    createdBy: {
        type: mongoose.Schema.Types.ObjectId,
        ref: 'User',
        required: true
    },

    // Danh sách người được giao công việc
    assigneeIds: [{
        type: mongoose.Schema.Types.ObjectId,
        ref: 'User'
    }],

    // Người phụ trách chính
    primaryAssigneeId: {
        type: mongoose.Schema.Types.ObjectId,
        ref: 'User'
    },

    // Danh sách người được chia sẻ công việc
    sharedWith: [{
        userId: {
            type: mongoose.Schema.Types.ObjectId,
            ref: 'User',
            required: true
        },
        permission: {
            type: String,
            enum: ['view', 'edit'],
            default: 'view'
        },
        sharedAt: {
            type: Date,
            default: Date.now
        }
    }],

    startDate: {
        type: Date
    },

    dueDate: {
        type: Date
    },

    priority: {
        type: String,
        enum: ['low', 'medium', 'high'],
        default: 'medium'
    },

    status: {
        type: String,
        enum: ['todo', 'in_progress', 'completed'],
        default: 'todo'
    }

}, { timestamps: true });

module.exports = mongoose.model('Task', taskSchema);
