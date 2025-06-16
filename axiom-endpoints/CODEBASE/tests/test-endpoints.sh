#!/bin/bash

# Test script for Axiom Endpoints TodoApi
# Make sure the TodoApi is running on http://localhost:5153

BASE_URL="http://localhost:5153"

echo "🚀 Testing Axiom Endpoints TodoApi"
echo "=================================="

# Test 1: Get all todos (should be empty initially)
echo "📝 GET /todos"
curl -s -X GET "$BASE_URL/todos" | jq '.' || curl -s -X GET "$BASE_URL/todos"
echo -e "\n"

# Test 2: Create a new todo
echo "📝 POST /todos - Create new todo"
TODO_RESPONSE=$(curl -s -X POST "$BASE_URL/todos" \
  -H "Content-Type: application/json" \
  -d '{"title": "Learn Axiom Endpoints"}')
echo "$TODO_RESPONSE" | jq '.' 2>/dev/null || echo "$TODO_RESPONSE"

# Extract todo ID from response (assuming it's in the response)
TODO_ID=$(echo "$TODO_RESPONSE" | jq -r '.id' 2>/dev/null || echo "12345678-1234-5678-9abc-123456789012")
echo "Created Todo ID: $TODO_ID"
echo -e "\n"

# Test 3: Get specific todo by ID
echo "📝 GET /todos/{id}"
curl -s -X GET "$BASE_URL/todos/$TODO_ID" | jq '.' 2>/dev/null || curl -s -X GET "$BASE_URL/todos/$TODO_ID"
echo -e "\n"

# Test 4: Create another todo
echo "📝 POST /todos - Create second todo"
TODO_RESPONSE2=$(curl -s -X POST "$BASE_URL/todos" \
  -H "Content-Type: application/json" \
  -d '{"title": "Build awesome APIs"}')
echo "$TODO_RESPONSE2" | jq '.' 2>/dev/null || echo "$TODO_RESPONSE2"
echo -e "\n"

# Test 5: Get all todos with query parameters
echo "📝 GET /todos?pageSize=5&page=1"
curl -s -X GET "$BASE_URL/todos?pageSize=5&page=1" | jq '.' 2>/dev/null || curl -s -X GET "$BASE_URL/todos?pageSize=5&page=1"
echo -e "\n"

# Test 6: Search todos
echo "📝 GET /todos?search=axiom"
curl -s -X GET "$BASE_URL/todos?search=axiom" | jq '.' 2>/dev/null || curl -s -X GET "$BASE_URL/todos?search=axiom"
echo -e "\n"

# Test 7: Filter by completion status
echo "📝 GET /todos?completed=false"
curl -s -X GET "$BASE_URL/todos?completed=false" | jq '.' 2>/dev/null || curl -s -X GET "$BASE_URL/todos?completed=false"
echo -e "\n"

echo "🎉 Test complete! Check the responses above."
echo ""
echo "💡 Features demonstrated:"
echo "  ✅ Type-safe routes (no magic strings)"
echo "  ✅ Automatic parameter binding" 
echo "  ✅ Query parameter support with filtering & pagination"
echo "  ✅ HATEOAS link generation"
echo "  ✅ Functional Result<T> error handling"
echo "  ✅ Clean endpoint definitions"