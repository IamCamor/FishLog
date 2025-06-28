<?php
// Set headers to allow requests from any origin (for development)
// In production, configure CORS more strictly, specifying specific domains
header("Access-Control-Allow-Origin: *");
header("Content-Type: application/json; charset=UTF-8");
header("Access-Control-Allow-Methods: POST, GET, DELETE, OPTIONS"); // Added GET and DELETE for future API calls
header("Access-Control-Max-Age: 3600");
header("Access-Control-Allow-Headers: Content-Type, Access-Control-Allow-Headers, Authorization, X-Requested-With");

// Check request method
if ($_SERVER['REQUEST_METHOD'] === 'OPTIONS') {
    // This is a CORS preflight request, just send headers and exit
    exit();
}

// Simple routing based on request method and path (for demonstration)
// In a real application, use a PHP framework (Laravel, Symfony) for proper routing
$request_uri = explode('/', trim($_SERVER['REQUEST_URI'], '/'));
$api_endpoint = end($request_uri); // Gets the last part of the URL, e.g., 'add_fishing_log.php'

// --- Handle POST requests (e.g., adding fishing logs, blog posts, comments) ---
if ($_SERVER['REQUEST_METHOD'] === 'POST') {
    $data = file_get_contents("php://input");
    $decodedData = json_decode($data, true); // Decode JSON into an associative array

    // Check if JSON decoding was successful
    if ($decodedData === null) {
        http_response_code(400); // Bad Request
        echo json_encode(array("success" => false, "message" => "Invalid JSON format or empty data."));
        exit();
    }

    // Simulate different API endpoints
    if ($api_endpoint === 'add_fishing_log.php') {
        // Here, you would connect to your database and insert $decodedData into 'fishing_logs' table
        // Example with PDO (commented out):
        /*
        $servername = "localhost";
        $username = "username";
        $password = "password";
        $dbname = "fishlog_db";
        try {
            $conn = new PDO("mysql:host=$servername;dbname=$dbname", $username, $password);
            $conn->setAttribute(PDO::ATTR_ERRMODE, PDO::ERRMODE_EXCEPTION);
            $stmt = $conn->prepare("INSERT INTO fishing_logs (user_id, user_name, fish_type, weight, length, location_name, notes, bait, tackle_brand, fishing_date, weather_condition, temperature) VALUES (:user_id, :user_name, :fish_type, :weight, :length, :location_name, :notes, :bait, :tackle_brand, :fishing_date, :weather_condition, :temperature)");
            $stmt->bindParam(':user_id', $decodedData['user_id']);
            $stmt->bindParam(':user_name', $decodedData['user_name']);
            $stmt->bindParam(':fish_type', $decodedData['fish_type']);
            $stmt->bindParam(':weight', $decodedData['weight']);
            $stmt->bindParam(':length', $decodedData['length']);
            $stmt->bindParam(':location_name', $decodedData['location_name']);
            $stmt->bindParam(':notes', $decodedData['notes']);
            $stmt->bindParam(':bait', $decodedData['bait']);
            $stmt->bindParam(':tackle_brand', $decodedData['tackle_brand']);
            $stmt->bindParam(':fishing_date', $decodedData['fishing_date']);
            $stmt->bindParam(':weather_condition', $decodedData['weather_condition']);
            $stmt->bindParam(':temperature', $decodedData['temperature']);
            $stmt->execute();
            http_response_code(200);
            echo json_encode(array("success" => true, "message" => "Fishing log saved successfully."));
        } catch(PDOException $e) {
            http_response_code(500);
            echo json_encode(array("success" => false, "message" => "Database error: " . $e->getMessage()));
        }
        $conn = null;
        */

        // Simulate successful saving for demonstration
        error_log("Received fishing log data: " . print_r($decodedData, true));
        http_response_code(200); // OK
        echo json_encode(array("success" => true, "message" => "Fishing log data received by backend (simulated save).", "received_data" => $decodedData));
        exit();
    } 
    // TODO: Add more POST endpoints here, e.g., for add_blog_post.php, add_comment.php, etc.
    /*
    else if ($api_endpoint === 'add_blog_post.php') {
        // Logic to save blog post to DB (with moderation status)
        error_log("Received blog post data: " . print_r($decodedData, true));
        http_response_code(200);
        echo json_encode(array("success" => true, "message" => "Blog post received for moderation."));
        exit();
    }
    else if ($api_endpoint === 'add_comment.php') {
        // Logic to save comment to DB (potentially with moderation status)
        error_log("Received comment data: " . print_r($decodedData, true));
        http_response_code(200);
        echo json_encode(array("success" => true, "message" => "Comment added."));
        exit();
    }
    */
    else {
        http_response_code(404); // Not Found
        echo json_encode(array("success" => false, "message" => "API endpoint not found for POST request."));
        exit();
    }
} 
// --- Handle DELETE requests (e.g., deleting fishing logs) ---
else if ($_SERVER['REQUEST_METHOD'] === 'DELETE') {
    $data = file_get_contents("php://input");
    $decodedData = json_decode($data, true);

    if ($decodedData === null || !isset($decodedData['id'])) {
        http_response_code(400); // Bad Request
        echo json_encode(array("success" => false, "message" => "Invalid JSON format or missing ID for DELETE."));
        exit();
    }

    if ($api_endpoint === 'delete_fishing_log.php') {
        $logId = $decodedData['id'];
        // Here, you would connect to your database and delete the entry with $logId
        // Simulate successful deletion
        error_log("Simulating deletion of fishing log with ID: " . $logId);
        http_response_code(200);
        echo json_encode(array("success" => true, "message" => "Fishing log deleted (simulated)."));
        exit();
    }
    // TODO: Add more DELETE endpoints here, e.g., for deleting blog posts, comments
    else {
        http_response_code(404); // Not Found
        echo json_encode(array("success" => false, "message" => "API endpoint not found for DELETE request."));
        exit();
    }
}
// --- Handle GET requests (e.g., fetching lists, rankings) ---
else if ($_SERVER['REQUEST_METHOD'] === 'GET') {
    // TODO: Implement GET endpoints here, e.g.,
    /*
    if ($api_endpoint === 'get_fishing_logs.php') {
        // Fetch all fishing logs from DB and return as JSON
        // For simulation, return a predefined list
        $simulatedLogs = [
            // ... (your simulated fishing log data as JSON)
        ];
        http_response_code(200);
        echo json_encode($simulatedLogs);
        exit();
    } else if ($api_endpoint === 'get_angler_rankings.php') {
        // Fetch angler rankings from DB and return as JSON
        $simulatedRankings = [
            // ... (your simulated angler ranking data as JSON)
        ];
        http_response_code(200);
        echo json_encode($simulatedRankings);
        exit();
    }
    // And so on for get_locations.php, get_competitions.php, get_blog_posts.php, get_comments.php etc.
    */
    
    // Default response for GET if no specific endpoint is matched
    http_response_code(404); // Not Found
    echo json_encode(array("success" => false, "message" => "API endpoint not found or not implemented for GET request."));
    exit();

} else {
    // Other methods not allowed
    http_response_code(405); // Method Not Allowed
    echo json_encode(array("success" => false, "message" => "Method not allowed."));
    exit();
}
?>
