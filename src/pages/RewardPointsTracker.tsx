import React, { useEffect, useState } from 'react';
import { supabase } from '../supabaseClient';
import { Session } from '@supabase/supabase-js';
import { Database } from '../types/supabase'; // Import the generated types

type Reward = Database['public']['Tables']['rewards']['Row'];

const RewardPointsTracker: React.FC = () => {
  const [rewards, setRewards] = useState<Reward | null>(null);
  const [loading, setLoading] = useState(true);
  const [error, setError] = useState<string | null>(null);
  const [session, setSession] = useState<Session | null>(null);

  useEffect(() => {
    const fetchSession = async () => {
      const { data: { session } } = await supabase.auth.getSession();
      setSession(session);
    };
    fetchSession();

    const { data: { subscription } } = supabase.auth.onAuthStateChange((_event, session) => {
      setSession(session);
    });

    return () => subscription.unsubscribe();
  }, []);


  useEffect(() => {
    const fetchRewards = async () => {
      if (!session?.user) {
        setLoading(false);
        setError('User not authenticated.');
        setRewards(null);
        return;
      }

      setLoading(true);
      setError(null);

      // Fetch rewards for the current user
      const { data, error } = await supabase
        .from('rewards')
        .select('*')
        .eq('user_id', session.user.id)
        .single(); // Assuming one rewards record per user

      if (error) {
        console.error('Error fetching rewards:', error);
        setError(error.message);
        setRewards(null);
      } else {
        setRewards(data);
      }
      setLoading(false);
    };

    if (session !== null) { // Only fetch if session state is known
       fetchRewards();
    }

  }, [session]); // Re-run when session changes

  if (loading) {
    return <div className="container mx-auto p-4">Loading rewards...</div>;
  }

  if (error) {
    return <div className="container mx-auto p-4 text-red-600">Error: {error}</div>;
  }

  if (!rewards) {
     return (
        <div className="container mx-auto p-4">
            <h1 className="text-3xl font-bold mb-6">Reward Points</h1>
            <p>No reward points data found for your account.</p>
        </div>
     );
  }

  return (
    <div className="container mx-auto p-4">
      <h1 className="text-3xl font-bold mb-6">Reward Points</h1>
      <div className="bg-white p-6 rounded-lg shadow">
        <h2 className="text-xl font-semibold mb-3">Your Points Balance</h2>
        <p className="text-gray-700 text-2xl font-bold">{rewards.points} Points</p>
        <p className="text-gray-500 text-sm mt-2">Last Updated: {new Date(rewards.last_updated).toLocaleString()}</p>
        {rewards.odoo_crm_link && (
             <p className="text-gray-500 text-sm mt-1">Odoo CRM Link: <a href={rewards.odoo_crm_link} target="_blank" rel="noopener noreferrer" className="text-indigo-600 hover:underline">View in Odoo</a></p>
        )}
        <p className="mt-4 text-gray-700">Keep earning points by placing orders and providing feedback!</p>
      </div>
    </div>
  );
};

export default RewardPointsTracker;
