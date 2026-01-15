import React, { useState, useEffect } from 'react';
import { View, Text, StyleSheet, ScrollView, Dimensions, Platform } from 'react-native';
import { useRobot } from '../features/RobotContext';
import { colors } from '../theme/colors';
import { LineChart } from 'react-native-chart-kit';
import { Header } from '../components/Header';
import Svg, { Circle, Defs, LinearGradient, Stop } from 'react-native-svg';
import { Activity } from 'lucide-react-native';
import { useLanguage } from '../features/LanguageContext';

const getScreenWidth = () => Dimensions.get("window").width;

export const DashboardScreen = () => {
    const { sensorData } = useRobot();
    const { t } = useLanguage();
    // Initialize with 20 zeros for a smooth start (no single-point crash)
    const [forceData, setForceData] = useState(Array(20).fill(0));
    const screenWidth = getScreenWidth();

    // Update graph data
    useEffect(() => {
        if (sensorData) {
            setForceData(prev => {
                // Keep exactly 20 points for scrolling effect
                const newData = [...prev, sensorData.force];
                if (newData.length > 20) return newData.slice(newData.length - 20);
                return newData;
            });
        }
    }, [sensorData]);

    // Safety check for display
    const currentForce = sensorData?.force || 0.0;
    const currentMaterial = sensorData?.material || "Unknown";
    const currentConf = sensorData?.confidence || 0;

    // Gauge Calculations
    const maxForce = 10;
    const radius = 80; // Slightly larger for impact
    const strokeWidth = 18;
    const circumference = 2 * Math.PI * radius;
    const progress = Math.min(Math.max(currentForce / maxForce, 0), 1);
    const strokeDashoffset = circumference - (progress * circumference);

    return (
        <View style={styles.container}>
            <Header title={t('dashboard')} />

            <ScrollView contentContainerStyle={styles.scrollContent} showsVerticalScrollIndicator={false}>

                {/* 1. Circular Force Gauge */}
                <View style={styles.gaugeContainer}>
                    <View style={styles.gaugeWrapper}>
                        <Svg height={radius * 2 + strokeWidth} width={radius * 2 + strokeWidth} viewBox={`0 0 ${(radius * 2 + strokeWidth)} ${(radius * 2 + strokeWidth)}`}>
                            <Defs>
                                <LinearGradient id="grad" x1="0" y1="0" x2="1" y2="0">
                                    <Stop offset="0" stopColor="#00E676" stopOpacity="1" />
                                    <Stop offset="1" stopColor="#69F0AE" stopOpacity="1" />
                                </LinearGradient>
                            </Defs>

                            {/* Background Circle (Track) */}
                            <Circle
                                cx={(radius + strokeWidth / 2)}
                                cy={(radius + strokeWidth / 2)}
                                r={radius}
                                stroke="#ECEFF1" // Very light grey
                                strokeWidth={strokeWidth}
                                fill="transparent" // Let wrapper background show through
                            />

                            {/* Progress Circle (Gradient) */}
                            <Circle
                                cx={(radius + strokeWidth / 2)}
                                cy={(radius + strokeWidth / 2)}
                                r={radius}
                                stroke="url(#grad)" // Use Gradient
                                strokeWidth={strokeWidth}
                                fill="transparent"
                                strokeDasharray={circumference}
                                strokeDashoffset={strokeDashoffset}
                                strokeLinecap="round"
                                rotation="-90"
                                origin={`${(radius + strokeWidth / 2)}, ${(radius + strokeWidth / 2)}`}
                            />
                        </Svg>

                        {/* Gauge Text Overlay */}
                        <View style={styles.gaugeTextContainer}>
                            <Text style={styles.gaugeValue}>{currentForce.toFixed(2)}</Text>
                            <Text style={styles.gaugeUnit}>N</Text>
                        </View>
                    </View>
                </View>

                {/* 2. Material Banner */}
                <View style={styles.materialCard}>
                    <View style={styles.materialIconCircle}>
                        <Activity size={24} color={colors.primary} />
                    </View>
                    <View style={styles.materialContent}>
                        <Text style={styles.materialTitle}>{currentMaterial}</Text>
                        <Text style={styles.materialSub}>{t('confidence')}: {currentConf.toFixed(2)}%</Text>
                    </View>
                </View>

                {/* 3. Chart Card */}
                <View style={styles.chartOuterCard}>
                    <View style={styles.chartInnerCard}>
                        <View style={styles.chartHeader}>
                            <Text style={styles.chartTitle}>{t('forceHistory')}</Text>
                            <View style={styles.liveBadge}>
                                <View style={styles.liveDot} />
                                <Text style={styles.liveText}>{t('live')}</Text>
                            </View>
                        </View>

                        <View style={{ position: 'relative', width: '100%', alignItems: 'center' }}>
                            {/* Y Axis Label Rotated */}
                            <Text style={styles.chartYAxisLabel}>{t('force')} (N)</Text>

                            <LineChart
                                data={{
                                    labels: ["", "", "", "", "", "Time →"], // Minimal X Labels
                                    datasets: [{
                                        data: forceData,
                                        color: (opacity = 1) => `rgba(13, 71, 161, ${opacity})`, // Blue line
                                    }]
                                }}
                                width={screenWidth - 80}
                                height={220}
                                fromZero={true}
                                yAxisInterval={2}
                                segments={5} // 0, 2, 4, 6, 8, 10
                                chartConfig={{
                                    backgroundColor: "#ffffff",
                                    backgroundGradientFrom: "#ffffff",
                                    backgroundGradientTo: "#ffffff",
                                    decimalPlaces: 0,
                                    color: (opacity = 1) => `rgba(0, 0, 0, ${opacity})`,
                                    labelColor: (opacity = 1) => `rgba(0, 0, 0, 0.4)`,
                                    propsForDots: { r: "3", strokeWidth: "1", stroke: "#0D47A1", fill: "#fff" }, // Hollow dots
                                    propsForBackgroundLines: { strokeDasharray: "5, 5", stroke: "#E0E0E0" },
                                    fillShadowGradient: "#29B6F6", // Light Blue Fill
                                    fillShadowGradientOpacity: 0.1,
                                }}
                                bezier // Smooth curves
                                style={styles.chart}
                                withInnerLines={true}
                                withOuterLines={false}
                                withVerticalLabels={true}
                                withHorizontalLabels={true}
                            />
                        </View>
                    </View>
                </View>

                <View style={{ height: 100 }} />
            </ScrollView>
        </View>
    );
};

const styles = StyleSheet.create({
    container: { flex: 1, backgroundColor: '#F8F9FA' },
    scrollContent: { alignItems: 'center', paddingHorizontal: 20 },

    // Gauge
    gaugeContainer: {
        marginTop: 24,
        marginBottom: 32,
        alignItems: 'center',
        justifyContent: 'center',
    },
    gaugeWrapper: {
        position: 'relative',
        alignItems: 'center',
        justifyContent: 'center',
        width: 180, // radius(80)*2 + stroke(20) approx
        height: 180,
        borderRadius: 90, // Make it a perfect circle
        backgroundColor: colors.primary, // Background for the shadow to cast from
        shadowColor: "#0D47A1",
        shadowOffset: { width: 0, height: 8 },
        shadowOpacity: 0.4,
        shadowRadius: 16,
        elevation: 10
    },
    gaugeTextContainer: {
        position: 'absolute',
        alignItems: 'center',
        justifyContent: 'center'
    },
    gaugeValue: {
        fontSize: 36,
        fontFamily: Platform.OS === 'ios' ? 'System' : 'Roboto',
        fontWeight: '900',
        color: 'white',
        textShadowColor: 'rgba(0,0,0,0.3)',
        textShadowOffset: { width: 0, height: 2 },
        textShadowRadius: 4
    },
    gaugeUnit: {
        fontSize: 16,
        fontWeight: '600',
        color: 'rgba(255,255,255,0.9)',
        marginTop: -2
    },

    // Material
    materialCard: {
        backgroundColor: colors.primary,
        width: '100%',
        borderRadius: 24,
        padding: 20,
        flexDirection: 'row',
        alignItems: 'center',
        marginBottom: 24,
        elevation: 6,
        shadowColor: '#000',
        shadowOffset: { width: 0, height: 4 },
        shadowOpacity: 0.25,
        shadowRadius: 8
    },
    materialIconCircle: {
        width: 48, height: 48,
        borderRadius: 24,
        backgroundColor: 'rgba(255,255,255,0.9)',
        justifyContent: 'center', alignItems: 'center',
        marginRight: 16
    },
    materialContent: { flex: 1 },
    materialTitle: {
        color: 'white',
        fontSize: 22,
        fontWeight: 'bold',
        marginBottom: 4
    },
    materialSub: {
        color: 'rgba(255,255,255,0.8)',
        fontSize: 14,
        fontWeight: '500'
    },

    // Chart
    chartOuterCard: {
        backgroundColor: '#E1F5FE', // Very Light Blue Frame
        width: '100%',
        borderRadius: 28,
        padding: 10,
        elevation: 4,
        shadowColor: '#000',
        shadowOffset: { width: 0, height: 2 },
        shadowOpacity: 0.1,
        shadowRadius: 6
    },
    chartInnerCard: {
        backgroundColor: 'white',
        borderRadius: 20,
        padding: 16,
        alignItems: 'center'
    },
    chartHeader: {
        flexDirection: 'row',
        width: '100%',
        justifyContent: 'space-between',
        alignItems: 'center',
        marginBottom: 20,
        paddingHorizontal: 8
    },
    chartTitle: {
        fontSize: 18,
        fontWeight: 'bold',
        color: '#455A64'
    },
    liveBadge: {
        flexDirection: 'row',
        alignItems: 'center',
        backgroundColor: '#FFEBEE',
        paddingHorizontal: 8,
        paddingVertical: 4,
        borderRadius: 12
    },
    liveDot: {
        width: 6, height: 6,
        borderRadius: 3,
        backgroundColor: '#D32F2F',
        marginRight: 6
    },
    liveText: {
        color: '#D32F2F',
        fontSize: 10,
        fontWeight: 'bold'
    },

    chart: {
        borderRadius: 16,
        paddingRight: 32, // More space for last label?
        marginLeft: -16   // Adjust centering
    },
    chartYAxisLabel: {
        position: 'absolute',
        left: -12,
        top: '50%',
        fontSize: 12,
        fontWeight: '600',
        color: '#90A4AE',
        transform: [{ rotate: '-90deg' }, { translateX: -20 }]
    }
});
