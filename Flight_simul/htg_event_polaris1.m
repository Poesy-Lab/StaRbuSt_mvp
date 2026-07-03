% % % RK4의 궤적 분석 시 지면을 뚫고 내려가는 것을 방지합니다.
function event = htg_event_polaris1(t,x)

event = (-x(3,1) < 0) && (x(4,1)<0);

end