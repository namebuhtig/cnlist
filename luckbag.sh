#!/bin/bash
## 联合组队开福袋
## Author: SuperManito
## Version: 1.0
## Modified: 2022-06-09

## 执行位置判定
if [ ${WORK_DIR} ]; then
    . ${WORK_DIR}/shell/share.sh
else
    echo -e "\n[\033[31mERROR\033[0m] 请进入容器内执行此脚本！\n"
    exit
fi
StartRunTime=$(date +%s)

cd ${WORK_DIR}
## 加载环境变量
Import_Config_Not_Check
Count_UserSum

## 使用帮助
function Help() {
    if [ -x /usr/local/bin/grab ]; then
        echo -e "\n${GREEN}使用方法${PLAIN}：在 ${BLUE}grab${PLAIN} 后面加上活动链接\n"
    else
        echo -e "\n${GREEN}使用方法${PLAIN}：使用 ${BLUE}bash${PLAIN} 执行此脚本并在后面加上活动链接\n"
    fi
}

## 计算时间
function CalculationUsedTime() {
    local FinalTime=$(date +%s)
    local UsedTime=$(($FinalTime - $1))
    if [ $UsedTime -lt 60 ]; then
        echo -e "${UsedTime}s"
    elif [ $UsedTime -ge 60 ] && [ $UsedTime -lt 3600 ]; then
        echo -e "$(($UsedTime / 60))m$(($UsedTime % 60))s"
    elif [ $UsedTime -ge 3600 ]; then
        echo -e "$(($UsedTime / 3600))h$((($UsedTime % 3600) / 60))m$((($UsedTime % 3600) % 60))s"
    fi
}

## URL编码
function UrlEncode() {
    local LANG=C
    local length="${#1}"
    i=0
    while :; do
        [ $length -gt $i ] && {
            local c="${1:$i:1}"
            case $c in
            [a-zA-Z0-9.~_-]) printf "$c" ;;
            *) printf '%%%02X' "'$c" ;;
            esac
        } || break
        let i++
    done
}

## URL解码
function UrlDecode() {
    u="${1//+/ }"
    echo -e "${u//%/\\x}"
}

## 随机定义一个UA
function Get_User_Agents() {
    local UA_Arrary=(
        "jdapp;iPhone;10.1.6;13.7;network/wifi;Mozilla/5.0 (iPhone; CPU iPhone OS 13_7 like Mac OS X) AppleWebKit/605.1.15 (KHTML, like Gecko) Mobile/15E148;supportJDSHWK/1",
        "jdapp;iPhone;10.1.6;14.1;network/wifi;Mozilla/5.0 (iPhone; CPU iPhone OS 14_1 like Mac OS X) AppleWebKit/605.1.15 (KHTML, like Gecko) Mobile/15E148;supportJDSHWK/1",
        "jdapp;iPhone;10.1.6;13.3;network/wifi;Mozilla/5.0 (iPhone; CPU iPhone OS 13_3 like Mac OS X) AppleWebKit/605.1.15 (KHTML, like Gecko) Mobile/15E148;supportJDSHWK/1",
        "jdapp;iPhone;10.1.6;13.4;network/wifi;Mozilla/5.0 (iPhone; CPU iPhone OS 13_4 like Mac OS X) AppleWebKit/605.1.15 (KHTML, like Gecko) Mobile/15E148;supportJDSHWK/1",
        "jdapp;iPhone;10.1.6;14.3;network/wifi;Mozilla/5.0 (iPhone; CPU iPhone OS 14_3 like Mac OS X) AppleWebKit/605.1.15 (KHTML, like Gecko) Mobile/15E148;supportJDSHWK/1",
        "jdapp;android;10.1.6;9;network/wifi;Mozilla/5.0 (Linux; Android 9; MI 6 Build/PKQ1.190118.001; wv) AppleWebKit/537.36 (KHTML, like Gecko) Version/4.0 Chrome/66.0.3359.126 MQQBrowser/6.2 TBS/044942 Mobile Safari/537.36",
        "jdapp;android;10.1.6;11;network/wifi;Mozilla/5.0 (Linux; Android 11; Redmi K30 5G Build/RKQ1.200826.002; wv) AppleWebKit/537.36 (KHTML, like Gecko) Version/4.0 Chrome/77.0.3865.120 MQQBrowser/6.2 TBS/045511 Mobile Safari/537.36",
        "jdapp;android;10.1.6;11;network/wifi;Mozilla/5.0 (Linux; Android 11; Redmi K20 Pro Premium Edition Build/RKQ1.200826.002; wv) AppleWebKit/537.36 (KHTML, like Gecko) Version/4.0 Chrome/77.0.3865.120 MQQBrowser/6.2 TBS/045513 Mobile Safari/537.36",
        "jdapp;android;10.1.6;10;network/wifi;Mozilla/5.0 (Linux; Android 10; M2006J10C Build/QP1A.190711.020; wv) AppleWebKit/537.36 (KHTML, like Gecko) Version/4.0 Chrome/77.0.3865.120 MQQBrowser/6.2 TBS/045230 Mobile Safari/537.36",
        "jdapp;android;10.1.6;11;network/wifi;Mozilla/5.0 (Linux; Android 11; Redmi K30 5G Build/RKQ1.200826.002; wv) AppleWebKit/537.36 (KHTML, like Gecko) Version/4.0 Chrome/77.0.3865.120 MQQBrowser/6.2 TBS/045511 Mobile Safari/537.36",
    )
    Num=$((${RANDOM} % 10))
    UA="${UA_Arrary[Num]}"
}

## 超级无线通用请求
# $1: 请求地址
# $2: 请求body
function Task() {
    curl -s -X POST "${Activity_Domain}/$1" \
        -H 'Connection: keep-alive' \
        -H 'Accept: application/json' \
        -H 'X-Requested-With: XMLHttpRequest' \
        -H "User-Agent: ${UA}" \
        -H 'Content-Type: application/x-www-form-urlencoded' \
        -H "Origin: ${Activity_Domain}" \
        -H 'Sec-Fetch-Site: same-origin' \
        -H 'Sec-Fetch-Mode: cors' \
        -H 'Sec-Fetch-Dest: empty' \
        -H 'Accept-Language: zh-CN,zh;q=0.9' \
        -H "Cookie: LZ_TOKEN_KEY=${LZ_TOKEN_KEY}; LZ_TOKEN_VALUE=${LZ_TOKEN_VALUE}" \
        --data-raw "$2"
}

## 获取 LZ_TOKEN_KEY 和 LZ_TOKEN_VALUE
function Get_LZ_TOKEN() {
    case ${Run_Mod} in
    lzkj)
        ## 尝试三次
        for ((n = 1; n < 4; n++)); do
            local data=$(curl -s "https://lzkj-isv.isvjd.com/wxCommonInfo/token")

            ## 判定请求结果
            if [[ $data != "" ]]; then
                result=$(echo $data | jq '.result' 2>/dev/null)
            else
                result="false"
            fi
            if [[ ${result} == "true" ]]; then
                LZ_TOKEN_KEY=$(echo $data | jq -r .data.LZ_TOKEN_KEY 2>/dev/null)
                LZ_TOKEN_VALUE=$(echo $data | jq -r .data.LZ_TOKEN_VALUE 2>/dev/null)
                break
            fi
            ## 报错获取失败，执行失败模式
            if [ $n = "3" ]; then
                echo -e "\n\n[${BLUE}$(date "+%Y-%m-%d %T")${PLAIN}] - $ERROR 接口 ${BLUE}wxCommonInfo/token${PLAIN} 请求异常，未能获取到 ${BLUE}LZ_TOKEN${PLAIN}！"
                exit
            fi
        done
        ;;

    cjhy)
        local data=$(curl -sI GET "${URL}")
        if [ $? -eq 0 ]; then
            LZ_TOKEN_KEY=$(echo $data | grep "LZ_TOKEN_KEY" | perl -pe "{s|.*LZ_TOKEN_KEY=([^; ]+)(?=;?).*|\1|}")
            LZ_TOKEN_VALUE=$(echo $data | grep "LZ_TOKEN_VALUE" | perl -pe "{s|.*LZ_TOKEN_VALUE=([^; ]+)(?=;?).*|\1|}")
        else
            echo -e "\n[${BLUE}$(date "+%Y-%m-%d %T")${PLAIN}] - $ERROR 活动页火爆，未能获取到 ${BLUE}LZ_TOKEN${PLAIN}！"
            exit
        fi
        ;;
    esac
}

## 获取用户pin
function Get_secretPin() {
    Pin=''
    nickname=''
    secretPin=''
    local token=''
    local result
    local CookieNum=$1
    local Tmp=Cookie$CookieNum
    local Cookie=${!Tmp}
    local pt_pin=$(echo ${Cookie} | perl -pe "{s|.*pt_pin=([^; ]+)(?=;?).*|\1|}")

    echo -e "\n[$(date "+%Y-%m-%d %T")] -【京东账号$NUM】$(UrlDecode $pt_pin)\n"

    ## 获取校验token
    function Get_token() {
        case ${Run_Mod} in
        lzkj)
            local BODY="body=%7B%22url%22%3A%20%22https%3A//lzdz1-isv.isvjcloud.com%22%2C%20%22id%22%3A%20%22%22%7D&uuid=72124265217d48b7955781024d65bbc4&client=apple&clientVersion=9.4.0&st=1621796702000&sv=120&sign=14f7faa31356c74e9f4289972db4b988"
            ;;
        cjhy)
            local BODY="body=%7B%22url%22%3A%22https%3A//cjhy-isv.isvjcloud.com%22%2C%22id%22%3A%22%22%7D&uuid=920cd9b12a1e621d91ca2c066f6348bb5d4b586b&client=apple&clientVersion=10.1.4&st=1633916729623&sv=102&sign=9eee1d69b69daf9e66659a049ffe075b"
            ;;
        esac
        token=$(curl -s -X POST 'https://api.m.jd.com/client.action?functionId=isvObfuscator' \
            -H 'Host: api.m.jd.com' \
            -H 'Content-Type: application/x-www-form-urlencoded' \
            -H 'User-Agent: JD4iPhone/167650 (iPhone; iOS 13.7; Scale/3.00)' \
            -H "Cookie: ${Cookie}" \
            --data-raw "${BODY}" | jq -r .token 2>/dev/null)
    }

    Get_token
    local data=$(Task customer/getMyPing "userId=${venderId}&token=${token}&fromType=APP")

    ## 判定请求结果
    if [[ $data != "" ]]; then
        result=$(echo $data | jq '.result' 2>/dev/null)
        nickname=$(echo $data | jq -r .data.nickname 2>/dev/null)
    else
        result="false"
        echo -e "ip可能黑了～"
    fi

    if [[ ${result} == "true" ]]; then
        secretPin="$(echo $data | jq -r .data.secretPin 2>/dev/null)"
        echo -e "你好，$nickname"
        echo -e "$secretPin"
        ## 处理pin
        case ${Run_Mod} in
        lzkj)
            Pin="${secretPin}"
            ;;
        cjhy)
            Pin="$(UrlEncode ${secretPin})"
            ;;
        esac
        ## 二次处理
        case ${Run_Mod} in
        lzkj)
            local data=$(Task common/accessLogWithAD "venderId=${venderId}&code=402&pin=${Pin}&activityId=${activityId}&pageUrl=$(UrlEncode ${URL})&subType=app")
            ;;
        cjhy)
            local data=$(Task common/accessLog "venderId=${venderId}&code=402&pin=${Pin}&activityId=${activityId}&pageUrl=$(UrlEncode ${URL})&subType=app")
            ;;
        esac
    else
        ## 如果获取到请求返回内容就打印错误内容
        if [[ $data != "" ]]; then
            echo $data | jq -r .errorMessage 2>/dev/null
        fi
        echo ''
    fi
}

function Run() {
    local result

    function LuckBag() {
        local result

        echo ''
        ## 抢个3次
        for ((i = 0; i <= 11; i++)); do
            [ $(($i % 3)) = 0 ] && Get_LZ_TOKEN
            local data=$(Task microDz/invite/openLuckBag/wx/followAllShop "activityId=${activityId}&buyerPin=${Pin}")
            ## 判定请求结果
            if [[ $data != "" ]]; then
                result=$(echo $data | jq .result 2>/dev/null)
                if [[ ${result} == "true" ]]; then
                    echo -e "获得5次抽奖机会"
                else
                    echo $data | jq -r .errorMessage 2>/dev/null
                    # echo $data
                fi
            else
                echo -e "接口回传信息为空"
            fi
        done
    }

    ## 随机定义一个UA
    Get_User_Agents
    ## 获取 LZ_TOKEN
    Get_LZ_TOKEN
    ## 获取店主ID
    venderId=$(Task customer/getSimpleActInfoVo "activityId=${activityId}" | jq .data.venderId 2>/dev/null)

    ## 账号屏蔽
    local TempBlock
    case ${Run_Mod} in
    lzkj)
        eval TempBlock="\$LZKJ_ZD_BLOCK"
        ;;
    cjhy)
        eval TempBlock="\$CJHY_ZD_BLOCK"
        ;;
    esac
    ## 全局屏蔽
    grep "^TempBlockCookie=" $FileConfUser -q 2>/dev/null
    if [ $? -eq 0 ]; then
        local GlobalBlockCookie=$(grep "^TempBlockCookie=" $FileConfUser | awk -F "[\"\']" '{print$2}')
    fi

    local NUM=1
    for ((UserNum = 1; UserNum <= ${UserSum}; UserNum++)); do

        ## 跳过单独屏蔽的账号
        for num in ${TempBlock}; do
            [[ $UserNum -eq $num ]] && continue 2
        done
        ## 跳过全局屏蔽的账号
        if [[ ${GlobalBlockCookie} ]]; then
            for num1 in ${GlobalBlockCookie}; do
                [[ $UserNum -eq $num1 ]] && continue 2
            done
        fi

        ## 获取 LZ_TOKEN
        Get_LZ_TOKEN
        ## 获取 pin
        Get_secretPin $UserNum
        let NUM++
        ## 获取不到pin就跳过
        [[ ! ${secretPin} ]] && sleep 1 && continue

        ## 任务
        LuckBag
        sleep 1 && echo ''
    done
}

function Main() {

    ## 检查链接格式并定义基础变量
    function CheckUrl() {
        URL="$1"
        echo "${URL}" | grep -Eq "https://.*-isv\.isv.*\.com/microDz/invite/openLuckBag/wx/view/.*\?activityId=.*"
        if [ $? -eq 0 ]; then
            ## 活动ID
            activityId=$(echo "${URL}" | perl -pe "{s|.*activityId=([^& ]+)(?=&?).*|\1|}")
            if [[ ${activityId} ]]; then
                ## 活动域名类型
                Run_Mod=$(echo ${URL} | cut -c 9-12)
                case ${Run_Mod} in
                lzkj | cjhy) ;;
                *)
                    echo -e "\n$ERROR 活动链接有误，活动类型未适配！\n"
                    exit
                    ;;
                esac
                ## 活动域名
                Activity_Domain="https://${Run_Mod}-isv.isvjd.com"
            else
                echo -e "\n$ERROR 活动链接有误，未能获取到活动ID！\n"
                exit
            fi
        else
            echo -e "\n$ERROR 活动链接有误，请验证！\n"
            exit
        fi
    }

    ## 检查链接
    CheckUrl "$1"
    Run
}

case $# in
1)
    Main "$1"
    ;;
*)
    Help
    ;;
esac
