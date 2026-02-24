import http from 'k6/http';
import { sleep, check } from 'k6';

export let options = {
    vus: 50,
    duration: '30s',
};

export default function () {
    const url = 'http://<BACKEND-SERVICE-IP>:8080/probability';
    const payload = JSON.stringify({
        hole: ['HA','HK'],
        board: [],
        players: 5,
        simulations: 10000
    });
    const params = { headers: { 'Content-Type': 'application/json' } };
    let res = http.post(url, payload, params);
    check(res, { 'status 200': (r) => r.status === 200 });
    sleep(1);
}
