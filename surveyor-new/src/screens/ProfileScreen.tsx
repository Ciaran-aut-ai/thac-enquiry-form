import React, { useCallback, useState } from 'react';
import { View, Text, ScrollView, TouchableOpacity, StyleSheet, ActivityIndicator, Alert, Dimensions } from 'react-native';
import { useFocusEffect } from '@react-navigation/native';
import { supabase } from '../lib/supabase';
import { Surveyor } from '../types';

function trafficLight(dateStr: string | null): string {
  if (!dateStr) return '⚪';
  const days = Math.ceil((new Date(dateStr).getTime() - Date.now()) / 86400000);
  if (days < 0)  return '🔴';
  if (days < 30) return '🟠';
  if (days < 90) return '🟡';
  return '🟢';
}

function formatDate(dateStr: string | null): string {
  if (!dateStr) return 'Not set';
  return new Date(dateStr).toLocaleDateString('en-GB', { day: 'numeric', month: 'short', year: 'numeric' });
}

export default function ProfileScreen() {
  const [surveyor, setSurveyor] = useState<Surveyor | null>(null);
  const [loading,  setLoading]  = useState(true);
  const [availability, setAvailability] = useState<Record<string, boolean>>({});
  const [savingAvail, setSavingAvail] = useState(false);

  useFocusEffect(useCallback(() => { loadProfile(); }, []));

  async function loadProfile() {
    setLoading(true);
    const { data: { user } } = await supabase.auth.getUser();
    if (!user) return;

    const { data: surveyorData } = await supabase
      .from('surveyors')
      .select('*')
      .eq('user_id', user.id)
      .single();

    setSurveyor(surveyorData);

    if (surveyorData?.id) {
      const { data: availData } = await supabase
        .from('surveyor_availability')
        .select('date, is_available')
        .eq('surveyor_id', surveyorData.id)
        .gte('date', new Date().toISOString().split('T')[0]);

      const availMap: Record<string, boolean> = {};
      availData?.forEach(a => { availMap[a.date] = a.is_available; });
      setAvailability(availMap);
    }

    setLoading(false);
  }

  async function toggleAvailability(date: string) {
    if (!surveyor) return;
    setSavingAvail(true);

    const newAvail = !availability[date];
    setAvailability(prev => ({ ...prev, [date]: newAvail }));

    try {
      const { error } = await supabase.from('surveyor_availability').upsert({
        surveyor_id: surveyor.id,
        date,
        is_available: newAvail,
      }, { onConflict: 'surveyor_id,date' });

      if (error) throw error;
    } catch (e: any) {
      Alert.alert('Error', e.message);
      setAvailability(prev => ({ ...prev, [date]: !newAvail }));
    } finally {
      setSavingAvail(false);
    }
  }

  async function signOut() {
    Alert.alert('Sign Out', 'Are you sure?', [
      { text: 'Cancel', style: 'cancel' },
      { text: 'Sign Out', style: 'destructive', onPress: () => supabase.auth.signOut() },
    ]);
  }

  if (loading) return <View style={s.center}><ActivityIndicator size="large" color="#1a3c2e" /></View>;
  if (!surveyor) return (
    <View style={s.center}>
      <Text style={s.noProfile}>No surveyor profile found.</Text>
      <Text style={s.hint}>Contact Trevor to link your account.</Text>
      <TouchableOpacity style={s.signOutBtn} onPress={signOut}>
        <Text style={s.signOutText}>Sign Out</Text>
      </TouchableOpacity>
    </View>
  );

  return (
    <ScrollView style={s.container} contentContainerStyle={{ padding: 16, gap: 12 }}>

      <View style={s.card}>
        <Text style={s.name}>{surveyor.full_name}</Text>
        <Text style={s.email}>{surveyor.email}</Text>
        {surveyor.phone ? <Text style={s.detail}>{surveyor.phone}</Text> : null}
        {surveyor.home_postcode ? <Text style={s.detail}>📍 {surveyor.home_postcode} · {surveyor.radius_miles} mile radius</Text> : null}
        {surveyor.hourly_rate ? <Text style={s.detail}>£{surveyor.hourly_rate}/hr</Text> : null}
      </View>

      <View style={s.card}>
        <Text style={s.sectionTitle}>Insurance & Compliance</Text>
        <View style={s.insuranceRow}>
          <View style={s.insuranceItem}>
            <Text style={s.insuranceLight}>{trafficLight(surveyor.pi_expiry)}</Text>
            <Text style={s.insuranceLabel}>PI Insurance</Text>
            <Text style={s.insuranceDate}>{formatDate(surveyor.pi_expiry)}</Text>
          </View>
          <View style={s.insuranceItem}>
            <Text style={s.insuranceLight}>{trafficLight(surveyor.pl_expiry)}</Text>
            <Text style={s.insuranceLabel}>PL Insurance</Text>
            <Text style={s.insuranceDate}>{formatDate(surveyor.pl_expiry)}</Text>
          </View>
          <View style={s.insuranceItem}>
            <Text style={s.insuranceLight}>{trafficLight(surveyor.dbs_expiry)}</Text>
            <Text style={s.insuranceLabel}>DBS Check</Text>
            <Text style={s.insuranceDate}>{formatDate(surveyor.dbs_expiry)}</Text>
          </View>
        </View>
      </View>

      {/* Availability Calendar */}
      <View style={s.card}>
        <Text style={s.sectionTitle}>Availability Calendar</Text>
        <Text style={s.calendarHint}>🟢 Available · 🔘 Unavailable</Text>
        {renderCalendar()}
      </View>

      <TouchableOpacity style={s.signOutBtn} onPress={signOut}>
        <Text style={s.signOutText}>Sign Out</Text>
      </TouchableOpacity>

    </ScrollView>
  );

  function renderCalendar() {
    const months: React.ReactNode[] = [];
    const today = new Date();

    for (let m = 0; m < 12; m++) {
      const monthDate = new Date(today.getFullYear(), today.getMonth() + m, 1);
      const monthName = monthDate.toLocaleDateString('en-GB', { month: 'long', year: 'numeric' });
      const daysInMonth = new Date(monthDate.getFullYear(), monthDate.getMonth() + 1, 0).getDate();
      const firstDay = monthDate.getDay();

      const days: React.ReactNode[] = [];
      for (let i = 0; i < firstDay; i++) days.push(<View key={`empty-${i}`} style={s.dayEmpty} />);

      for (let day = 1; day <= daysInMonth; day++) {
        const d = new Date(monthDate.getFullYear(), monthDate.getMonth(), day);
        const dateStr = d.toISOString().split('T')[0];
        const isAvail = availability[dateStr] !== false;

        days.push(
          <TouchableOpacity
            key={dateStr}
            style={[s.dayBtn, isAvail ? s.dayAvailable : s.dayUnavailable]}
            onPress={() => toggleAvailability(dateStr)}
            disabled={savingAvail}
          >
            <Text style={s.dayText}>{day}</Text>
          </TouchableOpacity>
        );
      }

      months.push(
        <View key={`month-${m}`} style={s.monthContainer}>
          <Text style={s.monthName}>{monthName}</Text>
          <View style={s.monthGrid}>{days}</View>
        </View>
      );
    }

    return <View>{months}</View>;
  }
}

const GREEN = '#1a3c2e';

const s = StyleSheet.create({
  container:     { flex: 1, backgroundColor: '#f5f5f5' },
  center:        { flex: 1, justifyContent: 'center', alignItems: 'center', padding: 24 },
  card:          { backgroundColor: '#fff', borderRadius: 12, padding: 16, elevation: 2 },
  name:          { fontSize: 22, fontWeight: '700', color: GREEN, marginBottom: 4 },
  email:         { fontSize: 14, color: '#6b7280', marginBottom: 4 },
  detail:        { fontSize: 14, color: '#374151', marginTop: 4 },
  sectionTitle:  { fontSize: 12, fontWeight: '700', color: GREEN, textTransform: 'uppercase', letterSpacing: 0.5, marginBottom: 16 },
  insuranceRow:  { flexDirection: 'row', justifyContent: 'space-around' },
  insuranceItem: { alignItems: 'center', gap: 4 },
  insuranceLight:{ fontSize: 28 },
  insuranceLabel:{ fontSize: 12, color: '#6b7280', fontWeight: '600', textAlign: 'center' },
  insuranceDate: { fontSize: 11, color: '#9ca3af', textAlign: 'center' },
  noProfile:     { fontSize: 18, fontWeight: '600', color: GREEN, marginBottom: 8 },
  hint:          { fontSize: 14, color: '#6b7280', textAlign: 'center', marginBottom: 24 },
  signOutBtn:    { backgroundColor: '#fee2e2', borderRadius: 12, padding: 16, alignItems: 'center', marginTop: 8 },
  signOutText:   { color: '#dc2626', fontWeight: '700', fontSize: 15 },
  calendarHint:  { fontSize: 12, color: '#6b7280', marginBottom: 12 },
  monthContainer:{ marginBottom: 20 },
  monthName:     { fontSize: 14, fontWeight: '700', color: GREEN, marginBottom: 8 },
  monthGrid:     { flexDirection: 'row', flexWrap: 'wrap', gap: 4 },
  dayBtn:        { width: '14.28%', aspectRatio: 1, justifyContent: 'center', alignItems: 'center', borderRadius: 6 },
  dayAvailable:  { backgroundColor: '#bbf7d0' },
  dayUnavailable:{ backgroundColor: '#f3f4f6' },
  dayEmpty:      { width: '14.28%', aspectRatio: 1 },
  dayText:       { fontSize: 12, fontWeight: '600', color: '#1a1a1a' },
});
