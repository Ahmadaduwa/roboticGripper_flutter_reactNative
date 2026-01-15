import React, { useState } from 'react';
import { View, Text, StyleSheet, TextInput, TouchableOpacity, ScrollView, Alert } from 'react-native';
import { Header } from '../components/Header';
import { colors } from '../theme/colors';
import { setApiBaseUrl, getApiBaseUrl, api } from '../api/api';
import { useLanguage } from '../features/LanguageContext';

export const SettingsScreen = () => {
    const { language, changeLanguage, t } = useLanguage();
    const [apiUrl, setApiUrl] = useState(getApiBaseUrl());

    const handleSave = async () => {
        const cleanUrl = apiUrl.trim();
        setApiBaseUrl(cleanUrl);
        setApiUrl(cleanUrl); // Update UI to reflect trimmed

        // Verify connection immediately
        const isConnected = await api.checkBackendAvailable();
        if (isConnected) {
            Alert.alert(t('save'), "Connected to Backend!");
        } else {
            Alert.alert(t('save'), "Connection Failed");
        }
    };

    return (
        <View style={styles.container}>
            <Header title={t('settings')} />

            <ScrollView style={styles.content}>

                {/* Language Section */}
                <View style={styles.card}>
                    <Text style={styles.sectionTitle}>{t('language')}</Text>
                    <View style={styles.divider} />

                    <View style={styles.langContainer}>
                        <TouchableOpacity
                            style={[styles.langBtn, language === 'TH' ? styles.langBtnActive : styles.langBtnInactive]}
                            onPress={() => changeLanguage('TH')}
                        >
                            <Text style={[styles.langText, language === 'TH' ? styles.langTextActive : styles.langTextInactive]}>TH</Text>
                        </TouchableOpacity>

                        <TouchableOpacity
                            style={[styles.langBtn, language === 'ENG' ? styles.langBtnActive : styles.langBtnInactive]}
                            onPress={() => changeLanguage('ENG')}
                        >
                            <Text style={[styles.langText, language === 'ENG' ? styles.langTextActive : styles.langTextInactive]}>ENG</Text>
                        </TouchableOpacity>
                    </View>
                </View>

                {/* Connection Settings */}
                <View style={styles.card}>
                    <Text style={styles.sectionTitle}>{t('connectionSettings')}</Text>
                    <View style={styles.divider} />

                    <Text style={styles.label}>{t('gripperApiUrl')}</Text>
                    <TextInput
                        style={styles.input}
                        value={apiUrl}
                        onChangeText={setApiUrl}
                        editable={true}
                        placeholder="http://10.0.2.2:8000"
                    />
                </View>

                {/* Save Button */}
                <TouchableOpacity style={styles.saveBtn} onPress={handleSave}>
                    <Text style={styles.saveBtnText}>{t('save')}</Text>
                </TouchableOpacity>

            </ScrollView>
        </View>
    );
};

const styles = StyleSheet.create({
    container: { flex: 1, backgroundColor: colors.background },
    content: { padding: 16 },

    card: {
        backgroundColor: colors.card,
        borderRadius: 20,
        padding: 20,
        marginBottom: 24,
        shadowColor: "#000",
        shadowOffset: { width: 0, height: 2 },
        shadowOpacity: 0.05,
        shadowRadius: 5,
        elevation: 3
    },
    sectionTitle: {
        fontSize: 18,
        fontWeight: 'bold',
        color: colors.text,
        marginBottom: 8
    },
    divider: {
        height: 1,
        backgroundColor: colors.border,
        marginBottom: 16,
        width: '100%'
    },

    // Language
    langContainer: {
        flexDirection: 'row',
        justifyContent: 'center',
        gap: 16
    },
    langBtn: {
        paddingVertical: 10,
        paddingHorizontal: 32,
        borderRadius: 24,
        minWidth: 100,
        alignItems: 'center'
    },
    langBtnInactive: {
        backgroundColor: '#EEEEEE',
    },
    langBtnActive: {
        backgroundColor: '#0047AB', // Deep blue active
    },
    langText: {
        fontWeight: 'bold',
        fontSize: 14
    },
    langTextInactive: { color: colors.text },
    langTextActive: { color: 'white' },

    // Connection
    label: {
        fontSize: 14,
        fontWeight: 'bold',
        color: colors.text,
        marginBottom: 8
    },
    input: {
        backgroundColor: '#E3F2FD', // Very light blue bg
        borderRadius: 8,
        padding: 16,
        color: colors.text,
        fontSize: 16
    },

    // Save
    saveBtn: {
        backgroundColor: colors.success,
        paddingVertical: 16,
        borderRadius: 30, // Pill shape
        alignItems: 'center',
        marginTop: 8
    },
    saveBtnText: {
        color: 'white',
        fontSize: 18,
        fontWeight: 'bold'
    }
});
