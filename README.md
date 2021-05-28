# GR_final_infospread by POOREUMOE KIM

COVID_19_Information_Spread_around_Political_Engagement_on_Facebook

[Presentation file](https://github.com/bluethou/COVID19_info_spread_Facebook/blob/main/Info_spread_presentation.pdf)

[Article](https://github.com/bluethou/COVID19_info_spread_Facebook/blob/main/%5BFinal%5D%20COVID_19_Information_Spread_around_Political_Engagement_on_Facebook.pdf)

Directory
- R_files: R codes and RData files
- csvfiles: csv files
- ipynb_files: jupyter notbook files

In R_files:
1) R scripts
- Crwaling_sharing_CNNposts.R: crawling posts that share CNN's 100 most interacted posts in 2020
- Crwaling_sharing_FoxNewsPosts.R: crawling posts that share Fox News's 100 most interacted posts in 2020
- NetworkMapping_CNNFOX_COVID.R: Create nodes and links files from the output of above two scripts. The resulting file can be imported in Gephi.
- TrendEDA_Pfizer_Trump.R: Exploratory data anlysis for how Pfizer's news and TrendEDA_Pfizer_Trump's argument spread on Facebook
- panel_data.R: Crawling panel data for prediction modeling

2) RData Files
- paneldata4.RData: crawled data by panel_data.R script
- CNN_FOX_COVID_2020.RData: crawled data by Crwaling_sharing_CNNposts.R and Crwaling_sharing_FoxNewsPosts.R script

In ipynb_files:
- Topic_timeseries.ipynb: Time-seires and sentiment analysis by Topics
- [For_Colab]Contextualized_Topic_Modeling.ipynb: Contextualized_Topic_Modeling script that Google Colab runs
- [For_Colab]prediction_model_evaluation.ipynb: Prediction model evaluation script that Google Colab runs


* 본 프로젝트는 Google의 GCP Credit 지원을 받고 있습니다.
