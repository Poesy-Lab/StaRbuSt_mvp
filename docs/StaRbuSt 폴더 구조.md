---
tags: []
---

# StaRbuSt 프로젝트 폴더 구조

이 문서는 StaRbuSt 시뮬레이션 프로젝트의 주요 폴더 및 MATLAB 스크립트(`.m`)와 해당 마크다운 문서(`.md`)가 함께 존재하는 파일들의 목록을 보여줍니다.

## 루트 폴더 (`StaRbuSt-Simulatrion(MATLAB)`)

- Test_StaRbuSt

## `Components` 폴더

### `1. Tank`

- Tank_LiqFeed
- Tank_PreFeed
- Tank_VapFeed

### `2. Vent-port`

- Vent_CdA
- Vent_ICF

### `5. Injector`

- Inj_ICF_VapFeed
- Inj_NHNE_LiqFeed
- InjState_LiqFeed
- InjState_VapFeed

### `6. Grain`

- Grain_aGn
- Update_GrainRadius

### `7. Combustor`

- Comb_Itercalc

### `8. Nozzle`

- Nozzle

## `Input` 폴더

- Init_Amb
- Init_Comb
- Init_Fuel
- Init_Inj
- Init_Nozzle
- Init_Simulset
- Init_Tank
- Init_Time
- Init_Vent
- Input

## `Output` 폴더

- PlotResults

### `1. Tank`

- Plot_Tank_h_t
- Plot_Tank_m_t
- Plot_Tank_P_t
- Plot_Tank_Results
- Plot_Tank_Rho_t
- Plot_Tank_Spec_cp_t
- Plot_Tank_Spec_cv_t
- Plot_Tank_Spec_h_t
- Plot_Tank_Spec_s_t
- Plot_Tank_Spec_u_t
- Plot_Tank_T_t
- Plot_Tank_Total_H_t
- Plot_Tank_Total_S_t
- Plot_Tank_X_t

### `2. Vent-port`

- Plot_Vent_Mdot_t
- Plot_Vent_Ratio_P_t
- Plot_Vent_Ratio_Pcr_t
- Plot_Vent_Results

### `5. Injector`

- Plot_Inj_Kappa_t
- Plot_Inj_Mdot_Combined_t
- Plot_Inj_P_t
- Plot_Inj_Ratio_P_t
- Plot_Inj_Ratio_Pcr_t
- Plot_Inj_Results
- Plot_Inj_Rho_t
- Plot_Inj_Spec_cp_t
- Plot_Inj_Spec_cv_t
- Plot_Inj_Spec_h_t
- Plot_Inj_Spec_s_t
- Plot_Inj_Spec_u_t
- Plot_Inj_State_t 
- Plot_Inj_T_t
- Plot_Inj_X_t

### `6. Grain`

- Plot_Grain_Ab_t
- Plot_Grain_Ap_t
- Plot_Grain_dRm_t
- Plot_Grain_Gox_t
- Plot_Grain_Mdot_t
- Plot_Grain_R_t
- Plot_Grain_Rdot_t
- Plot_Grain_Results

### `7. Combustor`

- Plot_Comb_Cstar_t
- Plot_Comb_Mdot_t
- Plot_Comb_OF_t
- Plot_Comb_P_t
- Plot_Comb_Results
- Plot_Comb_T_t

### `8. Nozzle`

- Plot_Nozzle_Cf_t
- Plot_Nozzle_F_t
- Plot_Nozzle_Isp_sl_t
- Plot_Nozzle_Results

## `Props` 폴더

- FluidEOS
- HelmholtzEOS
- N2O
- plot_EOS

## `System` 폴더

- LiqFeed
- PreFeed
- System
- VapFeed

