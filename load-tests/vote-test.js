import http from "k6/http";
import { check, sleep } from "k6";

const API_BASE_URL = __ENV.API_BASE_URL || "http://localhost:3001";

export const options = {
  scenarios: {
    voting_test: {
      executor: "constant-arrival-rate",
      rate: 1000,
      timeUnit: "1s",
      duration: "1m",
      preAllocatedVUs: 200,
      maxVUs: 1000,
    },
  },
  thresholds: {
    http_req_failed: ["rate<0.05"],
    http_req_duration: ["p(95)<500"],
  },
};

export default function () {
  const payload = JSON.stringify({
    participant_id: Math.random() > 0.5 ? 1 : 2,
  });

  const headers = {
    "Content-Type": "application/json",
    "User-Agent": "k6-load-test",
  };

  const response = http.post(`${API_BASE_URL}/api/votes`, payload, {
    headers,
  });

  check(response, {
    "status is 200 or 201": (r) => r.status === 200 || r.status === 201,
    "response time < 500ms": (r) => r.timings.duration < 500,
  });

  sleep(0.1);
}