import http from 'k6/http';
import { check, sleep } from 'k6';
import { Rate } from 'k6/metrics';


const quizFailureRate = new Rate('quiz_api_failures');
const locationFailureRate = new Rate('location_api_failures');
const timeFailureRate = new Rate('time_api_failures');
const exchangeFailureRate = new Rate('exchange_api_failures');

export let options = {
  stages: [
    { duration: '10s', target: 200},
    { duration: '20s', target: 200 },
    { duration: '20s', target: 300 },
    { duration: '20s', target: 300 },
    { duration: '10s', target: 0 }
  ],
  thresholds: {
    'http_req_failed': ['rate<0.2'],
    'http_req_duration': ['p(95)<30000'],
    'quiz_api_failures': ['rate<0.1'],
    'location_api_failures': ['rate<0.3'],
    'time_api_failures': ['rate<0.3'],
    'exchange_api_failures': ['rate<0.1'],
  },
};


const QUIZ_API_URL = 'https://opentdb.com';
const LOCATION_API_URL = 'https://nominatim.openstreetmap.org';
const TIME_API_URL = 'https://timeapi.io';
const EXCHANGE_RATE_BASE_URL = 'https://api.exchangerate-api.com/v4';


const quizParams = {
  timeout: '30s', 
};

const locationParams = {
  headers: {
    'User-Agent': 'HistoryQuizApp-k6-LoadTest/1.0',
  },
  timeout: '30s', 
};

const timeApiParams = {
  headers: {
    'Accept': 'application/json',
    'Content-Type': 'application/json',
  },
  timeout: '30s', 
};


const exchangeParams = {
  headers: {
    'Accept': 'application/json',
  },
  timeout: '30s'
};

function safeJsonCheck(response, path, expectedValue) {
  if (!response.body) return false;
  try {
    const data = response.json();
    const keys = path.split('.');
    let current = data;
    
    for (const key of keys) {
      if (current[key] === undefined) return false;
      current = current[key];
    }
    
    return expectedValue ? current === expectedValue : current !== undefined;
  } catch (e) {
    return false;
  }
}

export default function () {
  
  console.log(`VU ${__VU}: Testing Quiz API`);
  const quizResponse = http.get(`${QUIZ_API_URL}/api.php?amount=5&category=23&type=boolean&difficulty=easy`, quizParams);
  
  const quizSuccess = check(quizResponse, {
    'Quiz API - Status 200': (r) => r.status === 200,
    'Quiz API - Valid response': (r) => {
      if (r.status !== 200) return false;
      return safeJsonCheck(r, 'response_code', 0) && r.body.includes('results');
    },
  });
  
  quizFailureRate.add(!quizSuccess);
  
  sleep(2);

  const latVariation = Math.random() * 0.01 - 0.005;
  const lonVariation = Math.random() * 0.01 - 0.005;
  const lat = -6.175392 + latVariation;
  const lon = 106.827153 + lonVariation;
  
  console.log(`VU ${__VU}: Testing Location API`);
  const locationResponse = http.get(`${LOCATION_API_URL}/reverse?format=json&lat=${lat}&lon=${lon}&zoom=10`, locationParams);
  
  const locationSuccess = check(locationResponse, {
    'Location API - Status 200': (r) => r.status === 200,
    'Location API - Valid response': (r) => {
      if (r.status !== 200) return false;
      return safeJsonCheck(r, 'address.country_code', 'id') || r.body.includes('Indonesia');
    },
  });
  
  locationFailureRate.add(!locationSuccess);
  
  sleep(2);
  
  console.log(`VU ${__VU}: Testing Time API`);
  const timeResponse = http.get(`${TIME_API_URL}/api/time/current/coordinate?latitude=${lat}&longitude=${lon}`, timeApiParams);
  
  const timeSuccess = check(timeResponse, {
    'Time API - Status 200': (r) => r.status === 200,
    'Time API - Valid response': (r) => {
      if (r.status !== 200) return false;
      return r.body && (r.body.includes('timeZone') || r.body.includes('timezone'));
    },
  });
  
  timeFailureRate.add(!timeSuccess);
  
  sleep(2);

  console.log(`VU ${__VU}: Testing Exchange API`);
  const exchangeResponse = http.get(`${EXCHANGE_RATE_BASE_URL}/latest/USD`, exchangeParams);
  
  const exchangeSuccess = check(exchangeResponse, {
    'Exchange API - Status 200': (r) => r.status === 200,
    'Exchange API - Valid response': (r) => {
      if (r.status !== 200) return false;
      return (safeJsonCheck(r, 'result', 'success') || safeJsonCheck(r, 'success', true)) && r.body.includes('rates');
    },
  });
  
  exchangeFailureRate.add(!exchangeSuccess);
  
  sleep(3);
}

export function setup() {
  console.log('Starting load test with reduced load to respect external APIs');
}

export function teardown() {
  console.log('Load test completed');
}