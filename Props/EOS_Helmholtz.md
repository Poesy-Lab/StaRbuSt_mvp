---
tags:
  - 2상유동
  - Helmholtz
---
# 소개
- `EOS_Helmholtz.m`은

# Input
| 명칭     | 기호     | 비고  |
| ------ | ------ | --- |
| 온도     | $T$    |     |
| 밀도     | $\rho$ |     |


```MATLAB
% 아산화질소 물성치
Tc = 309.52; % K
rhoc = 452.011456; % kg/m^3
R_u = 8.31446261815324; % J/mol*K
M = 44.0128*1e-3; % kg/mol
R = R_u / M; % J/kg*K

% 이상 기체 기여분 상수 (아산화질소)
a1 = -4.4262736272;
a2 = 4.3120475243;
c0 = 3.5;
v = [2.1769, 1.6145, 0.48393];
u = [879.0, 2372.0, 5447.0];

% 잔여 비이상 기체 기여분 상수 (아산화질소)
n = zeros(1,12);
n(1) = 0.88045;
n(2) = -2.4235;
n(3) = 0.38237;
n(4) = 0.068917;
n(5) = 0.00020367;
n(6) = 0.13122;
n(7) = 0.46032;
n(8) = -0.0036985;
n(9) = -0.23263;
n(10) = -0.00042859;
n(11) = -0.042810;
n(12) = -0.023038;

% 무차원 헬름홀츠 에너지 무차원 인자
tau = Tc / T;
delta = rho / rhoc;

```

# System
## 1. 무차원 헬름홀츠 에너지
- 1.1 이상 기체 헬름홀츠 에너지 (임계온도 단위는 [K])
$$
\phi^{0}(\delta, \tau)=a_{1}+a_{2} \tau+\ln \delta+\left(c_{0}-1\right) \ln \tau-\frac{c_{1}T_{\mathrm{c}}^{c_{2}}}{c_{2}\left(c_{2}+1\right)} \tau^{-c_{2}}+ \\
\sum_{k=1}^{5} v_{k} \ln \left[1-\exp \left(-u_{k} \tau / T_{\mathrm{c}}\right)\right]
$$
```MATLAB
phio = ...
      a1                                          ... 
    + a2 * tau                                    ...  
    + log(delta)                                  ...  
    + (c0 - 1) * log(tau)                         ...  
    - (c1 * Tc^c2) / (c2 * (c2 + 1)) * tau^(-c2)  ...  
    + v1 * log(1 - exp(-u1 * tau / Tc))           ... 
    + v2 * log(1 - exp(-u2 * tau / Tc))           ...
    + v3 * log(1 - exp(-u3 * tau / Tc))           ...
    + v4 * log(1 - exp(-u4 * tau / Tc))           ...
    + v5 * log(1 - exp(-u5 * tau / Tc));
```

- 1.2 무극성 또는 극성 유체에 대한 잔여 비이상 기체 헬름홀츠 에너지
$$
\begin{gathered}
\phi^{r}(\delta, \tau)=n_{1} \delta \tau^{0.25}+n_{2} \delta \tau^{1.125}+n_{3} \delta \tau^{1.5}+n_{4} \delta^{2} \tau^{1.375}+ \\
n_{5} \delta^{3} \tau^{0.25}+n_{6} \delta^{7} \tau^{0.875}+n_{7} \delta^{2} \tau^{0.625} \exp ^{-\delta}+n_{8} \delta^{5} \tau^{1.75} \exp ^{-\delta}+ \\
n_{9} \delta \tau^{3.625} \exp ^{-\delta^{2}}+n_{10} \delta^{4} \tau^{3.625} \exp ^{-\delta^{2}}+n_{11} \delta^{3} \tau^{14.5} \exp ^{-\delta^{3}}+ \\
n_{12} \delta^{4} \tau^{12.0} \exp ^{-\delta^{3}}
\end{gathered} \tag{Non-Polar}
$$
$$
\begin{gathered}
\phi^{r}(\delta, \tau)=n_{1} \delta \tau^{0.25}+n_{2} \delta \tau^{1.25}+n_{3} \delta \tau^{1.5}+n_{4} \delta^{3} \tau^{0.25}+ \\
n_{5} \delta^{7} \tau^{0.875}+n_{6} \delta \tau^{2.375} \exp ^{-\delta}+n_{7} \delta^{2} \tau^{2.0} \exp ^{-\delta}+ \\
n_{8} \delta^{5} \tau^{2.125} \exp ^{-\delta}+n_{9} \delta \tau^{3.5} \exp ^{-\delta^{2}}+n_{10} \delta \tau^{6.5} \exp ^{-\delta^{2}}+ \\
n_{11} \delta^{4} \tau^{4.75} \exp ^{-\delta^{2}}+n_{12} \delta^{2} \tau^{12.5} \exp ^{-\delta^{3}}
\end{gathered}\tag{Polar}
$$
```MATLAB
switch fluid_state
    case 0          % Non‑Polar
        phir = ...
              n1  *  delta        * tau^(0.25)  ...                          
            + n2  *  delta        * tau^(1.125) ...                          
            + n3  *  delta        * tau^(1.5)   ...                          
            + n4  * (delta^2)     * tau^(1.375) ...                          
            + n5  * (delta^3)     * tau^(0.25)  ...                          
            + n6  * (delta^7)     * tau^(0.875) ...                          
            + n7  * (delta^2)     * tau^(0.625) * exp(-delta)   ...          
            + n8  * (delta^5)     * tau^(1.75)  * exp(-delta)   ...          
            + n9  *  delta        * tau^(3.625) * exp(-delta^2) ...          
            + n10 * (delta^4)     * tau^(3.625) * exp(-delta^2) ...          
            + n11 * (delta^3)     * tau^(14.5)  * exp(-delta^3) ...          
            + n12 * (delta^4)     * tau^(12.0)  * exp(-delta^3);
    case 1          % Polar
        phir = ...
              n1  *  delta        * tau^(0.25) ...
            + n2  *  delta        * tau^(1.25) ...
            + n3  *  delta        * tau^(1.5)  ...
            + n4  * (delta^3)     * tau^(0.25) ...
            + n5  * (delta^7)     * tau^(0.875) ...
            + n6  *  delta        * tau^(2.375) * exp(-delta) ...
            + n7  * (delta^2)     * tau^(2.0)   * exp(-delta) ...
            + n8  * (delta^5)     * tau^(2.125) * exp(-delta) ...
            + n9  *  delta        * tau^(3.5)   * exp(-delta^2) ...
            + n10 *  delta        * tau^(6.5)   * exp(-delta^2) ...
            + n11 * (delta^4)     * tau^(4.75)  * exp(-delta^2) ...
            + n12 * (delta^2)     * tau^(12.5)  * exp(-delta^3);
    otherwise
        error('fluid_state must be 0 (Non‑Polar) or 1 (Polar).');
end

```

- 1.3 무차원 헬름홀츠 에너지
$$
\phi(\delta, \tau)=\phi^{0}(\delta, \tau)+\phi^{r}(\delta, \tau)\tag{4}
$$
```MATLAB
phi = phio + phir;
```
## 2. 편미분된 무차원 헬름홀츠 에너지
- 2.1 이상 기체 헬름홀츠 에너지 편미분
$$
\frac{\partial \phi^o}{\partial \delta}
\;\equiv\;
\phi^o_{\delta}
\quad,\quad
\frac{\partial^2 \phi^o}{\partial \delta^2}
\;\equiv\;
\phi^o_{\delta\delta}
\quad,\quad
\frac{\partial^2 \phi^o}{\partial \delta\,\partial \tau}
\;\equiv\;
\phi^o_{\delta\tau}
\quad,\quad
\frac{\partial^2 \phi^o}{\partial \tau^2}
\;\equiv\;
\phi^o_{\tau\tau}\quad,\quad
\frac{\partial \phi^o}{\partial \tau}
\;\equiv\;
\phi^o_{\tau}
$$
$$
\phi^o_\delta = \frac{1}{\delta}
$$
$$
\phi^o_{\delta\delta} = -\frac{1}{\delta^2}
$$
$$
\phi^o_{\delta\tau} = 0
$$
$$
\phi^o_\tau=
a_{2}
+\frac{c_{0}-1}{\tau}
+\frac{c_{1} \,T_{\mathrm c}^{\,c_{2}}}{c_{2}+1}\,
  \tau^{-(c_{2}+1)}
+\sum_{k=1}^{5}
  v_{k}\,\frac{u_{k}}{T_{\mathrm c}}\,
  \frac{\exp\!\bigl(-u_{k}\tau/T_{\mathrm c}\bigr)}
       {1-\exp\!\bigl(-u_{k}\tau/T_{\mathrm c}\bigr)}
$$
$$
\phi^{0}_{\tau\tau}=
-\frac{c_{0}-1}{\tau^{2}}
\;-\;
c_{1}\,T_{\mathrm c}^{\,c_{2}}\,
      \tau^{-(\,c_{2}+2\,)}
\;-\;
\sum_{k=1}^{5}
        v_{k}\,
        \frac{u_{k}^{2}}{T_{\mathrm c}^{\,2}}\,
        \frac{\exp\!\bigl(-u_{k}\tau/T_{\mathrm c}\bigr)}
             {\bigl[\,1-\exp\!\bigl(-u_{k}\tau/T_{\mathrm c}\bigr)\bigr]^{2}}
$$
```MATLAB
phio_delta = 1 / delta;
phio_delta2 = - 1 / delta^2;
phio_delta_tau = 0;
phio_tau = ...
      a2 ...
    + (c0 - 1) / tau ...
    + (c1 * Tc^c2) / (c2 + 1) * tau^(-(c2 + 1)) ...
    + v1 * u1 / Tc * exp(-u1 * tau / Tc) / (1 - exp(-u1 * tau / Tc)) ...
    + v2 * u2 / Tc * exp(-u2 * tau / Tc) / (1 - exp(-u2 * tau / Tc)) ...
    + v3 * u3 / Tc * exp(-u3 * tau / Tc) / (1 - exp(-u3 * tau / Tc)) ...
    + v4 * u4 / Tc * exp(-u4 * tau / Tc) / (1 - exp(-u4 * tau / Tc)) ...
    + v5 * u5 / Tc * exp(-u5 * tau / Tc) / (1 - exp(-u5 * tau / Tc));
phio_tau2 = ...
	   -(c0 - 1) / tau^2 ...
	   -  c1 * Tc^c2 * tau^(-(c2 + 2)) ...
	   -  v1 * u1^2 / Tc^2 * exp(-u1 * tau / Tc) / (1 - exp(-u1 * tau / Tc))^2 ...
	   -  v2 * u2^2 / Tc^2 * exp(-u2 * tau / Tc) / (1 - exp(-u2 * tau / Tc))^2 ...
	   -  v3 * u3^2 / Tc^2 * exp(-u3 * tau / Tc) / (1 - exp(-u3 * tau / Tc))^2 ...
	   -  v4 * u4^2 / Tc^2 * exp(-u4 * tau / Tc) / (1 - exp(-u4 * tau / Tc))^2 ...
	   -  v5 * u5^2 / Tc^2 * exp(-u5 * tau / Tc) / (1 - exp(-u5 * tau / Tc))^2;
```

- 2.2  무극성 또는 극성 유체에 대한 잔여 비이상 기체 헬름홀츠 에너지 편미분
$$
\frac{\partial \phi^r}{\partial \delta}
\;\equiv\;
\phi^r_{\delta}
\quad,\quad
\frac{\partial^2 \phi^r}{\partial \delta^2}
\;\equiv\;
\phi^r_{\delta\delta}
\quad,\quad
\frac{\partial^2 \phi^r}{\partial \delta\,\partial \tau}
\;\equiv\;
\phi^r_{\delta\tau}
\quad,\quad
\frac{\partial^2 \phi^r}{\partial \tau^2}
\;\equiv\;
\phi^r_{\tau\tau}\quad,\quad
\frac{\partial \phi^r}{\partial \tau}
\;\equiv\;
\phi^r_{\tau}
$$
**<무극성 유체>**
$$
\begin{aligned}
\phi^{r}_{\delta}=\,&
  n_{1}\,\tau^{0.25}
 +n_{2}\,\tau^{1.125}
 +n_{3}\,\tau^{1.5}
 +2\,n_{4}\,\delta\,\tau^{1.375}
 +3\,n_{5}\,\delta^{2}\,\tau^{0.25}
 +7\,n_{6}\,\delta^{6}\,\tau^{0.875} \\[4pt]
&+n_{7}\,\tau^{0.625}\,e^{-\delta}\,(2\delta-\delta^{2})
 +n_{8}\,\tau^{1.75}\,e^{-\delta}\,(5\delta^{4}-\delta^{5}) \\[4pt]
&+n_{9}\,\tau^{3.625}\,e^{-\delta^{2}}\,(1-2\delta^{2})
 +n_{10}\,\tau^{3.625}\,e^{-\delta^{2}}\,(4\delta^{3}-2\delta^{5}) \\[4pt]
&+n_{11}\,\tau^{14.5}\,e^{-\delta^{3}}\,(3\delta^{2}-3\delta^{5})
 +n_{12}\,\tau^{12.0}\,e^{-\delta^{3}}\,(4\delta^{3}-3\delta^{6})
\end{aligned}
$$

$$
\begin{aligned}
\phi^{r}_{\delta\delta}=\;&
  2\,n_{4}\,\tau^{1.375}
+ 6\,n_{5}\,\delta\,\tau^{0.25}
+ 42\,n_{6}\,\delta^{5}\,\tau^{0.875} \\[4pt]
&+ n_{7}\,\tau^{0.625}\,e^{-\delta}\,
        \bigl(\delta^{2}-4\delta+2\bigr) \\[4pt]
&+ n_{8}\,\tau^{1.75}\,e^{-\delta}\,
        \bigl(\delta^{5}-10\delta^{4}+20\delta^{3}\bigr) \\[4pt]
&+ n_{9}\,\tau^{3.625}\,e^{-\delta^{2}}\,
        \bigl(4\delta^{3}-6\delta\bigr) \\[4pt]
&+ n_{10}\,\tau^{3.625}\,e^{-\delta^{2}}\,
        \bigl(4\delta^{6}-18\delta^{4}+12\delta^{2}\bigr) \\[4pt]
&+ n_{11}\,\tau^{14.5}\,e^{-\delta^{3}}\,
        \bigl(9\delta^{7}-24\delta^{4}+6\delta\bigr) \\[4pt]
&+ n_{12}\,\tau^{12.0}\,e^{-\delta^{3}}\,
        \bigl(9\delta^{8}-30\delta^{5}+12\delta^{2}\bigr)
\end{aligned}
$$

$$
\begin{aligned}
\phi^{r}_{\delta\tau}=\;&
  0.25\,n_{1}\,\tau^{-0.75}
+ 1.125\,n_{2}\,\tau^{0.125}
+ 1.5\,n_{3}\,\tau^{0.5}
+ 2.75\,n_{4}\,\delta\,\tau^{0.375} \\[4pt]
&+ 0.75\,n_{5}\,\delta^{2}\,\tau^{-0.75}
+ 6.125\,n_{6}\,\delta^{6}\,\tau^{-0.125} \\[4pt]
&+ 0.625\,n_{7}\,\tau^{-0.375}\,e^{-\delta}\,
       \bigl(2\delta-\delta^{2}\bigr) \\[4pt]
&+ 1.75\,n_{8}\,\tau^{0.75}\,e^{-\delta}\,
       \bigl(5\delta^{4}-\delta^{5}\bigr) \\[4pt]
&+ 3.625\,n_{9}\,\tau^{2.625}\,e^{-\delta^{2}}\,
       \bigl(1-2\delta^{2}\bigr) \\[4pt]
&+ 3.625\,n_{10}\,\tau^{2.625}\,e^{-\delta^{2}}\,
       \bigl(4\delta^{3}-2\delta^{5}\bigr) \\[4pt]
&+ 14.5\,n_{11}\,\tau^{13.5}\,e^{-\delta^{3}}\,
       \bigl(3\delta^{2}-3\delta^{5}\bigr) \\[4pt]
&+ 12.0\,n_{12}\,\tau^{11.0}\,e^{-\delta^{3}}\,
       \bigl(4\delta^{3}-3\delta^{6}\bigr)
\end{aligned}
$$

$$
\begin{aligned}
\phi^{r}_{\tau}=\;&
0.25\,n_{1}\,\delta\,\tau^{-0.75}
+1.125\,n_{2}\,\delta\,\tau^{0.125}
+1.5\,n_{3}\,\delta\,\tau^{0.5}
+1.375\,n_{4}\,\delta^{2}\,\tau^{0.375} \\[4pt]
&+0.25\,n_{5}\,\delta^{3}\,\tau^{-0.75}
+0.875\,n_{6}\,\delta^{7}\,\tau^{-0.125} \\[4pt]
&+0.625\,n_{7}\,\delta^{2}\,\tau^{-0.375}\,e^{-\delta}
+1.75\,n_{8}\,\delta^{5}\,\tau^{0.75}\,e^{-\delta} \\[4pt]
&+3.625\,n_{9}\,\delta\,\tau^{2.625}\,e^{-\delta^{2}}
+3.625\,n_{10}\,\delta^{4}\,\tau^{2.625}\,e^{-\delta^{2}} \\[4pt]
&+14.5\,n_{11}\,\delta^{3}\,\tau^{13.5}\,e^{-\delta^{3}}
+12.0\,n_{12}\,\delta^{4}\,\tau^{11.0}\,e^{-\delta^{3}}
\end{aligned}
$$

$$
\begin{aligned}
\phi^{r}_{\tau\tau}=\;&
-0.1875\,n_{1}\,\delta\,\tau^{-1.75}
\;+\;0.140625\,n_{2}\,\delta\,\tau^{-0.875}
\;+\;0.75\,n_{3}\,\delta\,\tau^{-0.5} \\[4pt]
&+0.515625\,n_{4}\,\delta^{2}\,\tau^{-0.625}
\;-\;0.1875\,n_{5}\,\delta^{3}\,\tau^{-1.75}
\;-\;0.109375\,n_{6}\,\delta^{7}\,\tau^{-1.125} \\[4pt]
&-0.234375\,n_{7}\,\delta^{2}\,\tau^{-1.375}\,e^{-\delta}
\;+\;1.3125\,n_{8}\,\delta^{5}\,\tau^{-0.25}\,e^{-\delta} \\[4pt]
&+9.515625\,n_{9}\,\delta\,\tau^{1.625}\,e^{-\delta^{2}}
\;+\;9.515625\,n_{10}\,\delta^{4}\,\tau^{1.625}\,e^{-\delta^{2}} \\[4pt]
&+195.75\,n_{11}\,\delta^{3}\,\tau^{12.5}\,e^{-\delta^{3}}
\;+\;132.0\,n_{12}\,\delta^{4}\,\tau^{10.0}\,e^{-\delta^{3}}
\end{aligned}
$$
---
**<극성 유체>**
$$
\begin{aligned}
\phi^{r}_{\delta}=\;&
n_{1}\,\tau^{0.25}
+n_{2}\,\tau^{1.25}
+n_{3}\,\tau^{1.5}
+3\,n_{4}\,\delta^{2}\,\tau^{0.25}
+7\,n_{5}\,\delta^{6}\,\tau^{0.875}\\[4pt]
&+n_{6}\,\tau^{2.375}\,e^{-\delta}\,\bigl(1-\delta\bigr)
+n_{7}\,\tau^{2.0}\,e^{-\delta}\,\bigl(2\delta-\delta^{2}\bigr)\\[4pt]
&+n_{8}\,\tau^{2.125}\,e^{-\delta}\,\bigl(5\delta^{4}-\delta^{5}\bigr)\\[4pt]
&+n_{9}\,\tau^{3.5}\,e^{-\delta^{2}}\,
       \bigl(1-2\delta^{2}\bigr)\\[4pt]
&+n_{10}\,\tau^{6.5}\,e^{-\delta^{2}}\,
        \bigl(1-2\delta^{2}\bigr)\\[4pt]
&+n_{11}\,\tau^{4.75}\,e^{-\delta^{2}}\,
        \bigl(4\delta^{3}-2\delta^{5}\bigr)\\[4pt]
&+n_{12}\,\tau^{12.5}\,e^{-\delta^{3}}\,
        \bigl(2\delta-3\delta^{4}\bigr)
\end{aligned}
$$
$$
\begin{aligned}
\phi^{r}_{\delta\delta}=\;&
 6\,n_{4}\,\delta\,\tau^{0.25}
+42\,n_{5}\,\delta^{5}\,\tau^{0.875}\\[4pt]
&+n_{6}\,\tau^{2.375}\,e^{-\delta}\,
     (\delta-2)\\[4pt]
&+n_{7}\,\tau^{2.0}\,e^{-\delta}\,
     \bigl(\delta^{2}-4\delta+2\bigr)\\[4pt]
&+n_{8}\,\tau^{2.125}\,e^{-\delta}\,
     \bigl(\delta^{5}-10\delta^{4}+20\delta^{3}\bigr)\\[4pt]
&+n_{9}\,\tau^{3.5}\,e^{-\delta^{2}}\,
     \bigl(4\delta^{3}-6\delta\bigr)\\[4pt]
&+n_{10}\,\tau^{6.5}\,e^{-\delta^{2}}\,
     \bigl(4\delta^{3}-6\delta\bigr)\\[4pt]
&+n_{11}\,\tau^{4.75}\,e^{-\delta^{2}}\,
     \bigl(4\delta^{6}-18\delta^{4}+12\delta^{2}\bigr)\\[4pt]
&+n_{12}\,\tau^{12.5}\,e^{-\delta^{3}}\,
     \bigl(9\delta^{6}-18\delta^{3}+2\bigr)
\end{aligned}
$$
$$
\begin{aligned}
\phi^{r}_{\delta\tau}=\;&
0.25\,n_{1}\,\tau^{-0.75}
\;+\;1.25\,n_{2}\,\tau^{0.25}
\;+\;1.5\,n_{3}\,\tau^{0.5}\\[4pt]
&+0.75\,n_{4}\,\delta^{2}\,\tau^{-0.75}
\;+\;6.125\,n_{5}\,\delta^{6}\,\tau^{-0.125}\\[4pt]
&+2.375\,n_{6}\,\tau^{1.375}\,e^{-\delta}\,(1-\delta)\\[4pt]
&+2\,n_{7}\,\tau^{1}\,e^{-\delta}\,(2\delta-\delta^{2})\\[4pt]
&+2.125\,n_{8}\,\tau^{1.125}\,e^{-\delta}\,(5\delta^{4}-\delta^{5})\\[4pt]
&+3.5\,n_{9}\,\tau^{2.5}\,e^{-\delta^{2}}\,(1-2\delta^{2})\\[4pt]
&+6.5\,n_{10}\,\tau^{5.5}\,e^{-\delta^{2}}\,(1-2\delta^{2})\\[4pt]
&+4.75\,n_{11}\,\tau^{3.75}\,e^{-\delta^{2}}\,(4\delta^{3}-2\delta^{5})\\[4pt]
&+12.5\,n_{12}\,\tau^{11.5}\,e^{-\delta^{3}}\,(2\delta-3\delta^{4})
\end{aligned}
$$
$$
\begin{aligned}
\phi^{r}_{\tau}=\;&
0.25\,n_{1}\,\delta\,\tau^{-0.75}
+1.25\,n_{2}\,\delta\,\tau^{0.25}
+1.5\,n_{3}\,\delta\,\tau^{0.5}\\[4pt]
&+0.25\,n_{4}\,\delta^{3}\,\tau^{-0.75}
+0.875\,n_{5}\,\delta^{7}\,\tau^{-0.125}\\[4pt]
&+2.375\,n_{6}\,\delta\,\tau^{1.375}\,e^{-\delta}
+2.0\,n_{7}\,\delta^{2}\,\tau^{1.0}\,e^{-\delta}\\[4pt]
&+2.125\,n_{8}\,\delta^{5}\,\tau^{1.125}\,e^{-\delta}\\[4pt]
&+3.5\,n_{9}\,\delta\,\tau^{2.5}\,e^{-\delta^{2}}
+6.5\,n_{10}\,\delta\,\tau^{5.5}\,e^{-\delta^{2}}\\[4pt]
&+4.75\,n_{11}\,\delta^{4}\,\tau^{3.75}\,e^{-\delta^{2}}
+12.5\,n_{12}\,\delta^{2}\,\tau^{11.5}\,e^{-\delta^{3}}
\end{aligned}
$$
$$
\begin{aligned}
\phi^{r}_{\tau\tau}=\;&
-0.1875\,n_{1}\,\delta\,\tau^{-1.75}
+0.3125\,n_{2}\,\delta\,\tau^{-0.75}
+0.75\,n_{3}\,\delta\,\tau^{-0.5}\\[4pt]
&-0.1875\,n_{4}\,\delta^{3}\,\tau^{-1.75}
-0.109375\,n_{5}\,\delta^{7}\,\tau^{-1.125}\\[4pt]
&+3.265625\,n_{6}\,\delta\,\tau^{0.375}\,e^{-\delta}
+2\,n_{7}\,\delta^{2}\,e^{-\delta}\\[4pt]
&+2.390625\,n_{8}\,\delta^{5}\,\tau^{0.125}\,e^{-\delta}\\[4pt]
&+8.75\,n_{9}\,\delta\,\tau^{1.5}\,e^{-\delta^{2}}
+35.75\,n_{10}\,\delta\,\tau^{4.5}\,e^{-\delta^{2}}\\[4pt]
&+17.8125\,n_{11}\,\delta^{4}\,\tau^{2.75}\,e^{-\delta^{2}}
+143.75\,n_{12}\,\delta^{2}\,\tau^{10.5}\,e^{-\delta^{3}}
\end{aligned}
$$
---
```MATLAB
switch fluid_state
    case 0          % Non‑Polar
		phir_delta = ...
	      n1  * tau^(0.25) ...
	    + n2  * tau^(1.125) ...
	    + n3  * tau^(1.5)   ...
	    + 2*n4  * delta      * tau^(1.375) ...
	    + 3*n5  * delta^2    * tau^(0.25)  ...
	    + 7*n6  * delta^6    * tau^(0.875) ...
	    + n7  * tau^(0.625)  * exp(-delta)   * (2*delta - delta^2) ...
	    + n8  * tau^(1.75)   * exp(-delta)   * (5*delta^4 - delta^5) ...
	    + n9  * tau^(3.625)  * exp(-delta^2) * (1 - 2*delta^2) ...
	    + n10 * tau^(3.625)  * exp(-delta^2) * (4*delta^3 - 2*delta^5) ...
	    + n11 * tau^(14.5)   * exp(-delta^3) * (3*delta^2 - 3*delta^5) ...
	    + n12 * tau^(12.0)   * exp(-delta^3) * (4*delta^3 - 3*delta^6);
	      
		phir_delta2 = ...
	      2*n4  * tau^(1.375) ...
	    + 6*n5  * delta      * tau^(0.25)  ...
	    + 42*n6 * delta^5    * tau^(0.875) ...
	    + n7  * tau^(0.625)  * exp(-delta)   * (delta^2      - 4*delta      + 2) ...
	    + n8  * tau^(1.75)   * exp(-delta)   * (delta^5      -10*delta^4    + 20*delta^3) ...
	    + n9  * tau^(3.625)  * exp(-delta^2) * (4*delta^3    - 6*delta) ...
	    + n10 * tau^(3.625)  * exp(-delta^2) * (4*delta^6    -18*delta^4    + 12*delta^2) ...
	    + n11 * tau^(14.5)   * exp(-delta^3) * (9*delta^7    -24*delta^4    + 6*delta) ...
	    + n12 * tau^(12.0)   * exp(-delta^3) * (9*delta^8    -30*delta^5    + 12*delta^2);
	      
		phir_delta_tau = ...
	      0.25  * n1  * tau^(-0.75) ...
	    + 1.125 * n2  * tau^(0.125) ...
	    + 1.5   * n3  * tau^(0.5)   ...
	    + 2.75  * n4  * delta      * tau^(0.375) ...
	    + 0.75  * n5  * delta^2    * tau^(-0.75) ...
	    + 6.125 * n6  * delta^6    * tau^(-0.125) ...
	    + 0.625 * n7  * tau^(-0.375) * exp(-delta)   * (2*delta - delta^2) ...
	    + 1.75  * n8  * tau^(0.75)  * exp(-delta)   * (5*delta^4 - delta^5) ...
	    + 3.625 * n9  * tau^(2.625) * exp(-delta^2) * (1 - 2*delta^2) ...
	    + 3.625 * n10 * tau^(2.625) * exp(-delta^2) * (4*delta^3 - 2*delta^5) ...
	    + 14.5  * n11 * tau^(13.5)  * exp(-delta^3) * (3*delta^2 - 3*delta^5) ...
	    + 12.0  * n12 * tau^(11.0)  * exp(-delta^3) * (4*delta^3 - 3*delta^6);
	      
	    phir_tau = ...
	      0.25  * n1  * delta      * tau^(-0.75) ...
	    + 1.125 * n2  * delta      * tau^(0.125) ...
	    + 1.5   * n3  * delta      * tau^(0.5)   ...
	    + 1.375 * n4  * delta^2    * tau^(0.375) ...
	    + 0.25  * n5  * delta^3    * tau^(-0.75) ...
	    + 0.875 * n6  * delta^7    * tau^(-0.125) ...
	    + 0.625 * n7  * delta^2    * tau^(-0.375) * exp(-delta) ...
	    + 1.75  * n8  * delta^5    * tau^(0.75)   * exp(-delta) ...
	    + 3.625 * n9  * delta      * tau^(2.625)  * exp(-delta^2) ...
	    + 3.625 * n10 * delta^4    * tau^(2.625)  * exp(-delta^2) ...
	    + 14.5  * n11 * delta^3    * tau^(13.5)   * exp(-delta^3) ...
	    + 12.0  * n12 * delta^4    * tau^(11.0)   * exp(-delta^3);
	      
		phir_tau2 = ...
		-0.1875    * n1  * delta      * tau^(-1.75) ...
		+ 0.140625 * n2  * delta      * tau^(-0.875) ...
		+ 0.75     * n3  * delta      * tau^(-0.5)   ...
		+ 0.515625 * n4  * delta^2    * tau^(-0.625) ...
		- 0.1875   * n5  * delta^3    * tau^(-1.75)  ...
		- 0.109375 * n6  * delta^7    * tau^(-1.125) ...
		- 0.234375 * n7  * delta^2    * tau^(-1.375) .* exp(-delta) ...
		+ 1.3125   * n8  * delta^5    * tau^(-0.25)  .* exp(-delta) ...
		+ 9.515625 * n9  * delta      * tau^(1.625)  .* exp(-delta.^2) ...
		+ 9.515625 * n10 * delta^4    * tau^(1.625)  .* exp(-delta.^2) ...
		+ 195.75   * n11 * delta^3    * tau^(12.5)   .* exp(-delta.^3) ...
		+ 132.0    * n12 * delta^4    * tau^(10.0)   .* exp(-delta.^3);
		  
    case 1          % Polar
        phir_delta = ...
	      n1  * tau^(0.25) ...
	    + n2  * tau^(1.25) ...
	    + n3  * tau^(1.5) ...
	    + 3*n4  * delta^2   * tau^(0.25) ...
	    + 7*n5  * delta^6   * tau^(0.875) ...
	    + n6  * tau^(2.375) * exp(-delta)   * (1        - delta) ...
	    + n7  * tau^(2.0)   * exp(-delta)   * (2*delta  - delta^2) ...
	    + n8  * tau^(2.125) * exp(-delta)   * (5*delta^4 - delta^5) ...
	    + n9  * tau^(3.5)   * exp(-delta^2) * (1        - 2*delta^2) ...
	    + n10 * tau^(6.5)   * exp(-delta^2) * (1        - 2*delta^2) ...
	    + n11 * tau^(4.75)  * exp(-delta^2) * (4*delta^3 - 2*delta^5) ...
	    + n12 * tau^(12.5)  * exp(-delta^3) * (2*delta   - 3*delta^4);
        
	    phir_delta2 = ...
	      6  * n4  * delta      * tau^(0.25) ...
	    + 42 * n5  * delta^5    * tau^(0.875) ...
	    + n6  * tau^(2.375) * exp(-delta)   .* ( delta         - 2 ) ...
	    + n7  * tau^(2.0)   * exp(-delta)   .* ( delta.^2      - 4*delta + 2 ) ...
	    + n8  * tau^(2.125) * exp(-delta)   .* ( delta.^5      -10*delta.^4 + 20*delta.^3 ) ...
	    + n9  * tau^(3.5)   * exp(-delta.^2).* ( 4*delta.^3    - 6*delta ) ...
	    + n10 * tau^(6.5)   * exp(-delta.^2).* ( 4*delta.^3    - 6*delta ) ...
	    + n11 * tau^(4.75)  * exp(-delta.^2).* ( 4*delta.^6    -18*delta.^4 + 12*delta.^2 ) ...
	    + n12 * tau^(12.5)  * exp(-delta.^3).* ( 9*delta.^6    -18*delta.^3 + 2 );
	      
		phir_delta_tau = ...
	      0.25  * n1  * tau^(-0.75) ...
	    + 1.25  * n2  * tau^(0.25)  ...
	    + 1.5   * n3  * tau^(0.5)   ...
	    + 0.75  * n4  * delta^2   * tau^(-0.75) ...
	    + 6.125 * n5  * delta^6   * tau^(-0.125) ...
	    + 2.375 * n6  * tau^(1.375) * exp(-delta)   .* (1        - delta) ...
	    + 2.0   * n7  * tau^(1.0)   * exp(-delta)   .* (2*delta  - delta.^2) ...
	    + 2.125 * n8  * tau^(1.125) * exp(-delta)   .* (5*delta.^4 - delta.^5) ...
	    + 3.5   * n9  * tau^(2.5)   * exp(-delta.^2).* (1        - 2*delta.^2) ...
	    + 6.5   * n10 * tau^(5.5)   * exp(-delta.^2).* (1        - 2*delta.^2) ...
	    + 4.75  * n11 * tau^(3.75)  * exp(-delta.^2).* (4*delta.^3 - 2*delta.^5) ...
	    + 12.5  * n12 * tau^(11.5)  * exp(-delta.^3).* (2*delta   - 3*delta.^4);
	      
		phir_tau = ...
	      0.25  * n1  * delta      * tau^(-0.75) ...
	    + 1.25  * n2  * delta      * tau^(0.25)  ...
	    + 1.5   * n3  * delta      * tau^(0.5)   ...
	    + 0.25  * n4  * delta^3    * tau^(-0.75) ...
	    + 0.875 * n5  * delta^7    * tau^(-0.125) ...
	    + 2.375 * n6  * delta      * tau^(1.375) .* exp(-delta) ...
	    + 2.0   * n7  * delta^2    * tau^(1.0)   .* exp(-delta) ...
	    + 2.125 * n8  * delta^5    * tau^(1.125) .* exp(-delta) ...
	    + 3.5   * n9  * delta      * tau^(2.5)   .* exp(-delta.^2) ...
	    + 6.5   * n10 * delta      * tau^(5.5)   .* exp(-delta.^2) ...
	    + 4.75  * n11 * delta^4    * tau^(3.75)  .* exp(-delta.^2) ...
	    + 12.5  * n12 * delta^2    * tau^(11.5)  .* exp(-delta.^3);
	      
		phir_tau2 = ...
		-0.1875    * n1  * delta      * tau^(-1.75) ...
		+ 0.3125    * n2  * delta      * tau^(-0.75) ...
		+ 0.75      * n3  * delta      * tau^(-0.5)  ...
		- 0.1875    * n4  * delta^3    * tau^(-1.75) ...
		- 0.109375  * n5  * delta^7    * tau^(-1.125) ...
		+ 3.265625  * n6  * delta      * tau^(0.375)  .* exp(-delta) ...
		+ 2.0       * n7  * delta^2    .* exp(-delta) ...
		+ 2.390625  * n8  * delta^5    * tau^(0.125)  .* exp(-delta) ...
		+ 8.75      * n9  * delta      * tau^(1.5)    .* exp(-delta.^2) ...
		+ 35.75     * n10 * delta      * tau^(4.5)    .* exp(-delta.^2) ...
		+ 17.8125   * n11 * delta^4    * tau^(2.75)   .* exp(-delta.^2) ...
		+ 143.75    * n12 * delta^2    * tau^(10.5)   .* exp(-delta.^3);
        
    otherwise
        error('fluid_state must be 0 (Non‑Polar) or 1 (Polar).');
end

```

## 3. 물성치 계산
- 3.1 압력 (+압축성 인자)
$$
Z = 1 + \delta\,\phi^r_\delta
$$
$$
P = Z \rho R T
$$
```MATLAB
Z = 1 + delta * phir_delta;
P = Z * rho * R * T;
```
- 3.2 내부 에너지
$$
\frac{u}{RT} \;=\; \tau \bigl(\phi_\tau^o + \phi_\tau^r\bigr)
$$
```MATLAB
u = (R * T) * tau * (phio_tau + phir_tau);
```
- 3.3 엔탈피
$$
\frac{h}{RT} \;=\; 1\;+\;\tau\bigl(\phi_\tau^o + \phi_\tau^r\bigr)\;+\;\delta\,\phi_\delta^r
$$
```MATLAB
h = (R * T) * (1 + tau * (phio_tau + phir_tau) + delta * phir_delta);
```
- 3.4 엔트로피
- 3.5 정적 비열
- 3.6 정압 비열
- 3.7 음속
- 3.8 줄-톰슨 계수
- 3.9 깁스 에너

# Output


# 전체 코드
