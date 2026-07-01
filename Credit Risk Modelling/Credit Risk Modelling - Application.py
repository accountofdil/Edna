import streamlit as st
import pandas as pd
import joblib

model = joblib.load('Credit Risk Modelling - Decision Tree Model.pkl')
encoders = {col: joblib.load(f'Credit Risk Modelling - Label Encoder ({col}).pkl') 
            for col in ['Sex', 'Housing', 'Saving accounts', 'Checking account']}

st.title('Credit Risk Prediction Application')
st.write('Enter applicant information to predict if credit risk is good or bad')

age = st.number_input('Age', min_value = 18, max_value = 80, value = 30)
sex = st.selectbox('Sex', ['male', 'female'])
job = st.number_input('Job (0-3)', min_value = 0, max_value = 3, value = 1)
housing = st.selectbox('Housing', ['own', 'rent', 'free'])
saving_accounts = st.selectbox('Saving Accounts', ['little', 'moderate', 'quite rich', 'rich'])
checking_account = st.selectbox('Checking Accounts', ['little', 'moderate', 'rich'])
credit_amount = st.number_input('Credit Amount', min_value = 0, value = 100)
duration = st.number_input('Duration (Months)', min_value = 1, default = 12)

input_df = pd.DataFrame({'Age': [age],
                         'Sex': [encoders['Sex'].transform([sex])[0]],
                         'Job': [job],
                         'Housing': [encoders['Housing'].transform([housing])[0]],
                         'Saving accounts': [encoders['Saving accounts'].transform([saving_accounts])[0]],
                         'Checking account': [encoders['Checking account'].transform([checking_account])[0]],
                         'Credit Amount': [credit_amount],
                         'Duration': [duration]})
                        
if st.button('Predict Risk'):
    prediction = model.predict(input_df)[0]
    if prediction == 1:
        st.success('The predicted credit risk is: **Good**')
    else:
        st.error('The predicted credit risk is: **Bad**')
    