import React from 'react';
import { View, Text, StyleSheet, StatusBar } from 'react-native';
import { colors } from '../theme/colors';
import { SafeAreaView } from 'react-native-safe-area-context';

export const Header = ({ title, leftIcon, rightIcon }) => {
    return (
        <View style={styles.container}>
            <SafeAreaView edges={['top']} style={styles.safeArea}>
                <View style={styles.content}>
                    <View style={{ width: 24 }}>
                        {leftIcon}
                    </View>
                    <Text style={styles.title}>{title}</Text>
                    <View style={{ width: 24 }}>
                        {rightIcon}
                    </View>
                </View>
            </SafeAreaView>
        </View>
    );
};

const styles = StyleSheet.create({
    container: {
        backgroundColor: colors.primary,
        paddingBottom: 16,
        borderBottomLeftRadius: 24,
        borderBottomRightRadius: 24,
        marginBottom: 16,
        shadowColor: "#000",
        shadowOffset: { width: 0, height: 4 },
        shadowOpacity: 0.2,
        shadowRadius: 8,
        elevation: 8,
        zIndex: 10
    },
    safeArea: {
        backgroundColor: colors.primary,
    },
    content: {
        flexDirection: 'row',
        alignItems: 'center',
        justifyContent: 'space-between',
        paddingHorizontal: 20,
        marginTop: 8,
    },
    title: {
        color: colors.headerText,
        fontSize: 26,
        fontWeight: '800', // Extra bold attempts to match the slab look
        letterSpacing: 0.5,
    }
});
