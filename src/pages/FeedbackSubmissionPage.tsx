import React, { useState } from 'react';

const FeedbackSubmissionPage: React.FC = () => {
   const [rating, setRating] = useState<number | null>(null);
  const [comment, setComment] = useState('');
  const [orderId, setOrderId] = useState(''); // Optional: Link feedback to a specific order
  const [loading, setLoading] = useState(false);
  const [message, setMessage] = useState<string | null>(null);
  const [error, setError] = useState<string | null>(null);

  const handleSubmit = async (e: React.FormEvent) => {
    e.preventDefault();
    setLoading(true);
    setMessage(null);
    setError(null);

    // TODO: Implement Supabase insert for feedback
    console.log('Submitting Feedback:', { rating, comment, orderId });

    // Simulate API call
    await new Promise(resolve => setTimeout(resolve, 1000));

    // Example Supabase insert (requires user_id from auth session)
    /*
    const { data, error: insertError } = await supabase
      .from('feedback')
      .insert([
        {
          user_id: (await supabase.auth.getSession()).data.session?.user.id, // Get current user ID
          order_id: orderId || null,
          rating: rating,
          comment: comment,
        },
      ]);

    if (insertError) {
      setError(insertError.message);
    } else {
      setMessage('Feedback submitted successfully!');
      setRating(null);
      setComment('');
      setOrderId('');
    }
    */

    setMessage('Feedback submission is a placeholder. Data is not saved.'); // Placeholder message
    setLoading(false);
  };

  return (
    <div className="container mx-auto p-4">
      <h1 className="text-3xl font-bold mb-6">Submit Feedback</h1>
      <p className="mb-4">We appreciate your feedback! Please let us know about your experience.</p>

      {message && <div className="bg-green-100 border border-green-400 text-green-700 px-4 py-3 rounded relative mb-4">{message}</div>}
      {error && <div className="bg-red-100 border border-red-400 text-red-700 px-4 py-3 rounded relative mb-4">{error}</div>}

      <form onSubmit={handleSubmit} className="bg-white p-6 rounded-lg shadow space-y-4">
         <div>
          <label htmlFor="orderId" className="block text-sm font-medium text-gray-700">Order ID (Optional)</label>
          <input
            id="orderId"
            name="orderId"
            type="text"
            className="mt-1 block w-full px-3 py-2 border border-gray-300 rounded-md shadow-sm focus:outline-none focus:ring-indigo-500 focus:border-indigo-500 sm:text-sm"
            value={orderId}
            onChange={(e) => setOrderId(e.target.value)}
          />
        </div>

        <div>
          <label className="block text-sm font-medium text-gray-700">Rating</label>
          <div className="mt-1 flex items-center space-x-2">
            {[1, 2, 3, 4, 5].map((star) => (
              <button
                key={star}
                type="button"
                className={`text-2xl ${rating &amp;&amp; rating >= star ? 'text-yellow-400' : 'text-gray-300'}`}
                onClick={() => setRating(star)}
              >
                ★
              </button>
            ))}
          </div>
           {rating === null && <p className="text-red-500 text-xs mt-1">Please select a rating.</p>}
        </div>

        <div>
          <label htmlFor="comment" className="block text-sm font-medium text-gray-700">Comment (Optional)</label>
          <textarea
            id="comment"
            name="comment"
            rows={4}
            className="mt-1 block w-full px-3 py-2 border border-gray-300 rounded-md shadow-sm focus:outline-none focus:ring-indigo-500 focus:border-indigo-500 sm:text-sm"
            value={comment}
            onChange={(e) => setComment(e.target.value)}
          ></textarea>
        </div>

        <div>
          <button
            type="submit"
            className="w-full flex justify-center py-2 px-4 border border-transparent rounded-md shadow-sm text-sm font-medium text-white bg-indigo-600 hover:bg-indigo-700 focus:outline-none focus:ring-2 focus:ring-offset-2 focus:ring-indigo-500 disabled:opacity-50"
            disabled={loading || rating === null}
          >
            {loading ? 'Submitting...' : 'Submit Feedback'}
          </button>
        </div>
      </form>
    </div>
  );
};

export default FeedbackSubmissionPage;
