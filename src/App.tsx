import React from 'react';
import { BrowserRouter as Router, Route, Routes, Navigate } from 'react-router-dom';
import LoginPage from './pages/LoginPage';
import RegisterPage from './pages/RegisterPage';
import CustomerDashboard from './pages/CustomerDashboard';
import AdminDashboard from './pages/AdminDashboard';
import OrderManagementPage from './pages/OrderManagementPage';
import FeedbackSubmissionPage from './pages/FeedbackSubmissionPage';
import RewardPointsTracker from './pages/RewardPointsTracker';
import { supabase } from './supabaseClient';
import { Session } from '@supabase/supabase-js';

// Basic Auth Provider/Context (can be expanded)
const AuthContext = React.createContext<Session | null | undefined>(undefined);

const AuthProvider: React.FC<{ children: React.ReactNode }> = ({ children }) => {
  const [session, setSession] = React.useState<Session | null | undefined>(undefined);

  React.useEffect(() => {
    supabase.auth.getSession().then(({ data: { session } }) => {
      setSession(session);
    });

    const {
      data: { subscription },
    } = supabase.auth.onAuthStateChange((_event, session) => {
      setSession(session);
    });

    return () => subscription.unsubscribe();
  }, []);

  return <AuthContext.Provider value={session}>{children}</AuthContext.Provider>;
};

const useAuth = () => {
  const context = React.useContext(AuthContext);
  if (context === undefined) {
    throw new Error('useAuth must be used within an AuthProvider');
  }
  return context;
};

// Protected Route Component
const ProtectedRoute: React.FC<{ element: React.ReactElement; allowedRoles?: ('customer' | 'admin')[] }> = ({ element, allowedRoles }) => {
  const session = useAuth();
  const [userRole, setUserRole] = React.useState<'customer' | 'admin' | null>(null);
  const [loading, setLoading] = React.useState(true);

  React.useEffect(() => {
    const fetchUserRole = async () => {
      if (session?.user) {
        const { data, error } = await supabase
          .from('users')
          .select('role')
          .eq('id', session.user.id)
          .single();

        if (error) {
          console.error('Error fetching user role:', error);
          setUserRole(null);
        } else {
          setUserRole(data?.role || null);
        }
      } else {
        setUserRole(null);
      }
      setLoading(false);
    };

    fetchUserRole();
  }, [session]);

  if (session === undefined || loading) {
    // Still checking session or fetching role
    return <div className="flex justify-center items-center h-screen">Loading...</div>;
  }

  if (!session) {
    // No session, redirect to login
    return <Navigate to="/login" replace />;
  }

  if (allowedRoles && userRole && !allowedRoles.includes(userRole)) {
    // Session exists, but role is not allowed
    // Redirect to a forbidden page or dashboard
    return <Navigate to={userRole === 'admin' ? '/admin/dashboard' : '/customer/dashboard'} replace />;
  }

  // Session exists and role is allowed (or no role restriction)
  return element;
};


function App() {
  return (
    <AuthProvider>
      <Router>
        <div className="min-h-screen bg-gray-100">
          {/* Navigation can go here, conditionally rendered based on auth state */}
          <Routes>
            <Route path="/login" element={<LoginPage />} />
            <Route path="/register" element={<RegisterPage />} />

            {/* Customer Routes */}
            <Route
              path="/customer/dashboard"
              element={<ProtectedRoute element={<CustomerDashboard />} allowedRoles={['customer']} />}
            />
             <Route
              path="/customer/orders"
              element={<ProtectedRoute element={<OrderManagementPage />} allowedRoles={['customer']} />}
            />
             <Route
              path="/customer/feedback"
              element={<ProtectedRoute element={<FeedbackSubmissionPage />} allowedRoles={['customer']} />}
            />
             <Route
              path="/customer/rewards"
              element={<ProtectedRoute element={<RewardPointsTracker />} allowedRoles={['customer']} />}
            />


            {/* Admin Routes */}
             <Route
              path="/admin/dashboard"
              element={<ProtectedRoute element={<AdminDashboard />} allowedRoles={['admin']} />}
            />
             {/* Add other admin routes here */}

            {/* Default redirect */}
            <Route path="/" element={<Navigate to="/login" replace />} />
             {/* Fallback for unknown routes - could be a 404 page */}
            <Route path="*" element={<Navigate to="/login" replace />} />
          </Routes>
        </div>
      </Router>
    </AuthProvider>
  );
}

export default App;
