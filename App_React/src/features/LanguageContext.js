import React, { createContext, useState, useContext, useEffect } from 'react';
import AsyncStorage from '@react-native-async-storage/async-storage';

// 1. Translation Dictionary
const translations = {
    ENG: {
        dashboard: "Dashboard",
        control: "Control",
        teaching: "Teaching",
        autoRun: "Auto Run",
        settings: "Settings",
        // Dashboard
        force: "Force",
        material: "Material",
        confidence: "Confidence",
        forceHistory: "Force History",
        live: "LIVE",
        connected: "CONNECTED",
        disconnected: "DISCONNECTED",
        // Settings
        language: "Language",
        connectionSettings: "Connection Settings",
        gripperApiUrl: "Gripper API URL",
        // Control
        manualControl: "Manual Control",
        systemStatus: "System Status",
        on: "ON",
        off: "OFF",
        gripperControl: "Gripper Control",
        forceLimit: "Force Limit (N)",
        jointControl: "Joint Control",
        open: "Open",
        closed: "Closed",

        // Teaching
        teachingMode: "Teaching Mode",
        savedPatterns: "Saved Patterns",
        createNewPattern: "CREATE NEW PATTERN",
        noPatterns: "No patterns yet",
        editPattern: "Edit Pattern",
        newPattern: "New Pattern",
        patternName: "Pattern Name",
        description: "Description",
        actionController: "Action Controller",
        addGrip: "ADD GRIP",
        addRelease: "ADD RELEASE",
        addPosition: "ADD POSITION",
        waitDuration: "Wait Duration",
        addWait: "ADD WAIT",
        recordedSequence: "Recorded Sequence",
        steps: "Steps",
        testingArea: "Testing Area",
        playSequence: "PLAY SEQUENCE",
        stopSequence: "STOP SEQUENCE",
        savePattern: "SAVE PATTERN",
        clearAll: "Clear All",
        stepsCount: "steps",
        enterName: "Enter name",
        addDesc: "Add a description...",

        // Auto Run
        systemReady: "System Ready",
        systemOffline: "System Offline",
        runConfiguration: "Run Configuration",
        selectPattern: "Select Pattern",
        cycleCount: "Cycle Count",
        maxForceLimit: "Max Force Limit",
        logFilename: "Log Filename",
        startAutoRun: "START AUTO RUN",
        stopAutoRun: "STOP AUTO RUN",
        executionLogs: "Recent Execution Logs",
        download: "Download",
        delete: "Delete",
        running: "Running...",
        cycles: "Cycles",
        status: "Status",

        // General
        cancel: "Cancel",
        create: "Create",
        confirmDelete: "Confirm Delete",
        areYouSureDelete: "Are you sure you want to delete",
        success: "Success",
        error: "Error",
        saved: "Saved",
        failed: "Failed",
    },
    TH: {
        dashboard: "แผงควบคุม",
        control: "ควบคุม",
        teaching: "สอนหุ่นยนต์",
        autoRun: "ทำงานอัตโนมัติ",
        settings: "ตั้งค่า",
        // Dashboard
        force: "แรงกด",
        material: "วัสดุ",
        confidence: "ความมั่นใจ",
        forceHistory: "ประวัติแรงกด",
        live: "สด",
        connected: "เชื่อมต่อแล้ว",
        disconnected: "ไม่เชื่อมต่อ",
        // Settings
        language: "ภาษา",
        connectionSettings: "ตั้งค่าการเชื่อมต่อ",
        gripperApiUrl: "API URL ของกริปเปอร์",
        save: "บันทึก",

        // Control
        manualControl: "การควบคุมแบบแมนนวล",
        systemStatus: "สถานะระบบ",
        on: "เปิด",
        off: "ปิด",
        gripperControl: "ควบคุมกริปเปอร์",
        forceLimit: "จำกัดแรงกด (N)",
        jointControl: "ควบคุมข้อต่อ",
        open: "กางออก",
        closed: "หุบเข้า",

        // Teaching
        teachingMode: "โหมดสอน",
        savedPatterns: "รูปแบบที่บันทึกไว้",
        createNewPattern: "สร้างรูปแบบใหม่",
        noPatterns: "ยังไม่มีรูปแบบ",
        editPattern: "แก้ไขรูปแบบ",
        newPattern: "รูปแบบใหม่",
        patternName: "ชื่อรูปแบบ",
        description: "คำอธิบาย",
        actionController: "ตัวควบคุมการกระทำ",
        addGrip: "เพิ่มการจับ",
        addRelease: "เพิ่มการปล่อย",
        addPosition: "เพิ่มตำแหน่ง",
        waitDuration: "ระยะเวลารอ",
        addWait: "เพิ่มการรอ",
        recordedSequence: "ลำดับที่บันทึก",
        steps: "ขั้นตอน",
        testingArea: "พื้นที่ทดสอบ",
        playSequence: "เล่นลำดับ",
        stopSequence: "หยุดลำดับ",
        savePattern: "บันทึกรูปแบบ",
        clearAll: "ล้างทั้งหมด",
        stepsCount: "ขั้นตอน",
        enterName: "กรอกชื่อ",
        addDesc: "เพิ่มคำอธิบาย...",

        // Auto Run
        systemReady: "ระบบพร้อม",
        systemOffline: "ระบบออฟไลน์",
        runConfiguration: "ตั้งค่าการทำงาน",
        selectPattern: "เลือกรูปแบบ",
        cycleCount: "จำนวนรอบ",
        maxForceLimit: "จำกัดแรงกดสูงสุด",
        logFilename: "ชื่อไฟล์บันทึก",
        startAutoRun: "เริ่มทำงานอัตโนมัติ",
        stopAutoRun: "หยุดทำงานอัตโนมัติ",
        executionLogs: "ประวัติการทำงานล่าสุด",
        download: "ดาวน์โหลด",
        delete: "ลบ",
        running: "กำลังทำงาน...",
        cycles: "รอบ",
        status: "สถานะ",

        // General
        cancel: "ยกเลิก",
        create: "สร้าง",
        confirmDelete: "ยืนยันการลบ",
        areYouSureDelete: "คุณแน่ใจหรือไม่ที่จะลบ",
        success: "สำเร็จ",
        error: "ผิดพลาด",
        saved: "บันทึกแล้ว",
        failed: "ล้มเหลว",
    }
};

// 2. Context
const LanguageContext = createContext();

// 3. Provider
export const LanguageProvider = ({ children }) => {
    const [language, setLanguage] = useState('ENG');

    // Load saved language
    useEffect(() => {
        AsyncStorage.getItem('user_language').then((saved) => {
            if (saved === 'TH' || saved === 'ENG') {
                setLanguage(saved);
            }
        });
    }, []);

    const changeLanguage = async (lang) => {
        setLanguage(lang);
        await AsyncStorage.setItem('user_language', lang);
    };

    const t = (key) => {
        return translations[language][key] || key;
    };

    return (
        <LanguageContext.Provider value={{ language, changeLanguage, t }}>
            {children}
        </LanguageContext.Provider>
    );
};

// 4. Hook
export const useLanguage = () => useContext(LanguageContext);
