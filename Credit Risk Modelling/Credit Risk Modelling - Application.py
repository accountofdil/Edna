import streamlit as st
import pandas as pd
import joblib

model = joblib.load('Credit Risk Modelling - Decision Tree Model.pkl')

st.title('Credit Risk Prediction Application')
st.write('Enter applicant information to predict if credit risk is good or bad')

age = st.number_input('Age', min_value = 18, max_value = 80, value = 30)
sex = st.selectbox('Sex', ['male', 'female'])
job = st.number_input('Job (0-3)', min_value = 0, max_value = 3, value = 1)
housing = st.selectbox('Housing', ['own', 'rent', 'free'])
saving_accounts = st.selectbox('Saving Accounts', ['little', 'moderate', 'quite rich', 'rich'])
checking_account = st.selectbox('Checking Accounts', ['little', 'moderate', 'rich'])
credit_amount = st.number_input('Credit Amount', min_value = 0, value = 100)

sex_map = {'male': 1, 'female': 0}
housing_map = {'own': 0, 'rent': 1, 'free': 2}
saving_map = {'little': 0, 'moderate': 1, 'quite rich': 2, 'rich': 3}
checking_map = {'little': 0, 'moderate': 1, 'rich': 2}

input_df = pd.DataFrame({'Age': [age],
                         'Sex': [sex_map[sex]],
                         'Job': [job],
                         'Housing': [housing_map[housing]],
                         'Saving accounts': [saving_map[saving_accounts]],
                         'Checking account': [checking_map[checking_account]],
                         'Credit amount': [credit_amount]})

if st.button('Predict Risk'):
    
    prediction = model.predict(input_df)[0]

    if prediction == 1:
        st.success('The predicted credit risk is: **Good**')
        
    else:
        st.error('The predicted credit risk is: **Bad**')
    