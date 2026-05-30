import React, { useCallback, useState } from 'react';
import { View, Text, ScrollView, TouchableOpacity, StyleSheet, ActivityIndicator, Alert } from 'react-native';
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

  useFocusEffect(useCallback(() => { loadProfile(); }, []));

  async function loadProfile() {
    setLoading(true);
    const { data: { user } } = await supabase.auth.getUser();
    if (!user) return;

    const { data } = await supabase
      .from('surveyors')
      .select('*')
      .eq('user_id', user.id)
      .single();

    setSurveyor(data);
    setLoading(false);
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

      <TouchableOpacity style={s.signOutBtn} onPress={signOut}>
        <Text style={s.signOutText}>Sign Out</Text>
      </TouchableOpacity>

    </ScrollView>
  );
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
});
