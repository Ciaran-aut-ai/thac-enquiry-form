import React, { useEffect, useState, useCallback } from 'react';
import { View, StyleSheet, ActivityIndicator, Text, TouchableOpacity, Alert } from 'react-native';
import MapView, { Marker, Callout, Region } from 'react-native-maps';
import { useFocusEffect, useNavigation } from '@react-navigation/native';
import { NativeStackNavigationProp } from '@react-navigation/native-stack';
import { supabase } from '../lib/supabase';
import { Job, RootStackParamList } from '../types';

const URGENCY_COLORS: Record<string, string> = {
  red: '#dc2626', orange: '#ea580c', yellow: '#ca8a04', grey: '#9ca3af', green: '#16a34a',
};

const SURVEY_LABELS: Record<string, string> = {
  bs5837: 'BS5837', vta: 'VTA', bc: 'BS5837 Stage 2', subs: 'Subsidence',
  mortgage: 'Mortgage', amendment: 'Amendment', other: 'Other',
};

export default function JobMapScreen() {
  const [jobs,    setJobs]    = useState<Job[]>([]);
  const [loading, setLoading] = useState(true);
  const nav = useNavigation<NativeStackNavigationProp<RootStackParamList>>();

  useFocusEffect(useCallback(() => { loadJobs(); }, []));

  async function loadJobs() {
    setLoading(true);
    const { data, error } = await supabase
      .from('jobs')
      .select('id,reference,survey_type,site_postcode,site_lat,site_lng,urgency_state,dispatch_state,sla_deadline,surveyor_pay_amount')
      .eq('dispatch_state', 'red')        // available only
      .not('site_lat', 'is', null)
      .not('site_lng', 'is', null);

    if (error) Alert.alert('Error', error.message);
    else setJobs(data || []);
    setLoading(false);
  }

  if (loading) {
    return <View style={s.center}><ActivityIndicator size="large" color="#1a3c2e" /></View>;
  }

  return (
    <View style={s.container}>
      <MapView
        style={s.map}
        initialRegion={{ latitude: 51.5, longitude: -1.5, latitudeDelta: 3, longitudeDelta: 3 }}
        showsUserLocation
      >
        {jobs.map(job => (
          <Marker
            key={job.id}
            coordinate={{ latitude: job.site_lat!, longitude: job.site_lng! }}
            pinColor={URGENCY_COLORS[job.urgency_state] || '#9ca3af'}
          >
            <Callout onPress={() => nav.navigate('JobDetail', { jobId: job.id })}>
              <View style={s.callout}>
                <Text style={s.calloutRef}>{job.reference || 'No ref'}</Text>
                <Text style={s.calloutType}>{SURVEY_LABELS[job.survey_type] || job.survey_type}</Text>
                <Text style={s.calloutPostcode}>{job.site_postcode || '—'}</Text>
                {job.surveyor_pay_amount ? (
                  <Text style={s.calloutPay}>£{job.surveyor_pay_amount.toFixed(0)} surveyor pay</Text>
                ) : null}
                <Text style={s.calloutTap}>Tap to view →</Text>
              </View>
            </Callout>
          </Marker>
        ))}
      </MapView>

      <View style={s.badge}>
        <Text style={s.badgeText}>{jobs.length} available job{jobs.length !== 1 ? 's' : ''}</Text>
      </View>

      <TouchableOpacity style={s.refresh} onPress={loadJobs}>
        <Text style={s.refreshText}>↻</Text>
      </TouchableOpacity>
    </View>
  );
}

const s = StyleSheet.create({
  container: { flex: 1 },
  map:       { flex: 1 },
  center:    { flex: 1, justifyContent: 'center', alignItems: 'center' },
  callout:   { width: 180, padding: 4 },
  calloutRef:      { fontWeight: '700', fontSize: 14, color: '#1a3c2e' },
  calloutType:     { fontSize: 12, color: '#374151', marginTop: 2 },
  calloutPostcode: { fontSize: 12, color: '#6b7280' },
  calloutPay:      { fontSize: 13, fontWeight: '600', color: '#16a34a', marginTop: 4 },
  calloutTap:      { fontSize: 11, color: '#9ca3af', marginTop: 6 },
  badge: {
    position: 'absolute', top: 16, left: 16,
    backgroundColor: '#1a3c2e', borderRadius: 20, paddingHorizontal: 14, paddingVertical: 6,
  },
  badgeText: { color: '#fff', fontSize: 13, fontWeight: '600' },
  refresh: {
    position: 'absolute', bottom: 24, right: 24,
    backgroundColor: '#1a3c2e', width: 48, height: 48, borderRadius: 24,
    justifyContent: 'center', alignItems: 'center', elevation: 4,
  },
  refreshText: { color: '#fff', fontSize: 22 },
});
