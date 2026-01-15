import React, { useState, useEffect, useRef } from 'react';
import { View, Text, StyleSheet, ScrollView, TouchableOpacity, Animated } from 'react-native';
import Slider from '@react-native-community/slider';
import { useRobot } from '../features/RobotContext';
import { api } from '../api/api';
import { colors } from '../theme/colors';
import { Header } from '../components/Header';
import { Lock } from 'lucide-react-native';

import { useLanguage } from '../features/LanguageContext';

export const ControlScreen = () => {
    const { sensorData } = useRobot();
    const { t } = useLanguage();

    // Gripper State
    const [maxForce, setMaxForce] = useState(5.0);
    const [gripperAngle, setGripperAngle] = useState(55);
    const [isOn, setIsOn] = useState(false);

    // UI State
    const [errorMsg, setErrorMsg] = useState(null);

    // Debounced Handlers
    const sendGripperTimeout = useRef(null);

    const updateState = (newState) => {
        // Update Local State immediatly for UI responsiveness
        if (newState.maxForce !== undefined) setMaxForce(newState.maxForce);
        if (newState.gripperAngle !== undefined) setGripperAngle(newState.gripperAngle);
        if (newState.isOn !== undefined) setIsOn(newState.isOn);

        // Prepare payload (using latest state + overrides)
        const payload = {
            maxForce: newState.maxForce !== undefined ? newState.maxForce : maxForce,
            angle: newState.gripperAngle !== undefined ? newState.gripperAngle : gripperAngle,
            switchOn: newState.isOn !== undefined ? newState.isOn : isOn,
        };

        // Send API (Debounced)
        clearTimeout(sendGripperTimeout.current);
        sendGripperTimeout.current = setTimeout(async () => {
            const success = await api.sendGripperCommand(payload);
            if (!success) {
                setErrorMsg("System Busy");
                setTimeout(() => setErrorMsg(null), 2000);
            }
        }, 100); // Fast debounce
    };

    return (
        <View style={styles.container}>
            <Header title={t('manualControl')} />

            <ScrollView contentContainerStyle={styles.content}>

                {errorMsg && (
                    <View style={styles.errorBanner}>
                        <Lock size={16} color="white" />
                        <Text style={styles.errorText}>{errorMsg}</Text>
                    </View>
                )}

                {/* Max Force Section */}
                <View style={styles.section}>
                    <Text style={styles.label}>{t('forceLimit')}</Text>
                    <Text style={styles.valueDisplay}>{maxForce.toFixed(2)} N</Text>

                    <Slider
                        style={styles.slider}
                        minimumValue={0}
                        maximumValue={10}
                        step={0.1}
                        value={maxForce}
                        onValueChange={(v) => updateState({ maxForce: v })}
                        minimumTrackTintColor={colors.accent} // Light Blue
                        maximumTrackTintColor="#EEEEEE"
                        thumbTintColor={colors.accent}
                    />

                    <View style={styles.rangeLabels}>
                        <Text style={styles.rangeText}>0 N</Text>
                        <Text style={styles.rangeText}>10 N</Text>
                    </View>
                </View>

                {/* Gripper Section */}
                <View style={styles.section}>
                    <Text style={styles.label}>{t('gripperControl')}</Text>
                    <Text style={styles.valueDisplay}>{gripperAngle.toFixed(2)}°</Text>

                    <Slider
                        style={styles.slider}
                        minimumValue={0}
                        maximumValue={180}
                        step={1}
                        value={gripperAngle}
                        onValueChange={(v) => updateState({ gripperAngle: v })}
                        minimumTrackTintColor={colors.accent}
                        maximumTrackTintColor="#EEEEEE"
                        thumbTintColor={colors.accent}
                    />

                    <View style={styles.rangeLabels}>
                        <Text style={styles.rangeText}>{t('closed')} (0°)</Text>
                        <Text style={styles.rangeText}>{t('open')} (180°)</Text>
                    </View>
                </View>

                {/* Custom Power Switch */}
                <View style={styles.switchContainer}>
                    <TouchableOpacity
                        style={[styles.customSwitch, isOn ? styles.switchOn : styles.switchOff]}
                        onPress={() => updateState({ isOn: !isOn })}
                        activeOpacity={0.8}
                    >
                        <Text style={styles.switchText}>{isOn ? t('on') : t('off')}</Text>
                        <View style={[styles.switchThumb, isOn ? { right: 8 } : { left: 8 }]} />
                    </TouchableOpacity>
                </View>

            </ScrollView>
        </View>
    );
};

const styles = StyleSheet.create({
    container: { flex: 1, backgroundColor: 'white' }, // Clean white bg
    content: { padding: 24, paddingBottom: 100 },

    // Sections
    section: {
        marginBottom: 40,
    },
    label: {
        fontSize: 18,
        fontWeight: 'bold',
        color: '#424242', // Dark Grey
        marginBottom: 16
    },
    valueDisplay: {
        fontSize: 48,
        fontWeight: '900',
        color: 'black',
        textAlign: 'center',
        marginBottom: 8
    },

    // Slider
    slider: {
        width: '100%',
        height: 40,
        transform: [{ scaleY: 1.2 }] // Slightly thicker feel
    },
    rangeLabels: {
        flexDirection: 'row',
        justifyContent: 'space-between',
        paddingHorizontal: 10,
    },
    rangeText: {
        fontSize: 12,
        fontWeight: 'bold',
        color: 'black'
    },

    // Error
    errorBanner: {
        position: 'absolute', top: 0, left: 24, right: 24, zIndex: 10,
        backgroundColor: colors.danger,
        padding: 12,
        borderRadius: 8,
        flexDirection: 'row', alignItems: 'center', gap: 8,
        justifyContent: 'center'
    },
    errorText: { color: 'white', fontWeight: 'bold' },

    // Custom Switch
    switchContainer: {
        alignItems: 'center',
        marginTop: 20
    },
    customSwitch: {
        width: 200,
        height: 70,
        borderRadius: 35,
        justifyContent: 'center',
        paddingHorizontal: 8,
        shadowColor: "#000",
        shadowOffset: { width: 0, height: 4 },
        shadowOpacity: 0.2,
        shadowRadius: 8,
        elevation: 6
    },
    switchOn: {
        backgroundColor: '#00E676', // Bright Green
    },
    switchOff: {
        backgroundColor: '#EF5350', // Red
    },
    switchThumb: {
        position: 'absolute',
        width: 54,
        height: 54,
        borderRadius: 27,
        backgroundColor: 'white',
        top: 8
    },
    switchText: {
        fontSize: 28,
        fontWeight: 'bold',
        color: 'white',
        textAlign: 'center',
        // Offset text based on state to not overlap thumb
        // Simple decentering for now
    }
});
