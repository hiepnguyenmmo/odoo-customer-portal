import React from 'react';

const OrderManagementPage: React.FC = () => {
  return (
    <div className="container mx-auto p-4">
      <h1 className="text-3xl font-bold mb-6">Order Management</h1>
      <p>This page will display the customer's order history, fetched from Supabase (synced with Odoo).</p>
      {/* Placeholder for Order List Component */}
      <div className="mt-6 p-4 bg-white rounded-lg shadow">
        <h2 className="text-xl font-semibold mb-3">Your Orders</h2>
        <ul className="list-disc pl-5">
          <li>Order #12345 - Status: Shipped</li>
          <li>Order #12346 - Status: Processing</li>
          {/* More orders here */}
        </ul>
      </div>
    </div>
  );
};

export default OrderManagementPage;
