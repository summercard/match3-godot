class_name MonsterEcologyDB
extends RefCounted

## 1.3.2：111 个物种逐一编写的生态核心，不按元素套模板。
const CORES := {
	"monster_001": {"origin": "晨露浸透的古老蜗壳", "habitat": "苔石、浅沟与叶背", "niche": "啃食衰叶并拖运细小草籽"},
	"monster_002": {"origin": "第一窝风草编成的软巢", "habitat": "矮草坡、花圃与树根", "niche": "梳理草叶并播撒带绒花种"},
	"monster_003": {"origin": "草兔足印积存的青翠灵气", "habitat": "菜畦、草垛与低灌木", "niche": "挖开硬土并埋藏成熟种荚"},
	"monster_004": {"origin": "平原古树冠落下的王冠芽", "habitat": "古树台、花海与林缘", "niche": "引导兔群修复大片枯萎草场"},
	"monster_005": {"origin": "树冠风铃摇落的轻盈羽絮", "habitat": "钟树、高枝与风口", "niche": "携花粉越过林冠并预报风向"},
	"monster_006": {"origin": "暴风眼中盘旋不散的羽流", "habitat": "断崖、云杉与峡口", "niche": "疏导强风并护送迁飞小鸟群"},
	"monster_007": {"origin": "牧草穗间聚起的温暖绒团", "habitat": "缓坡、牧草与篱笆", "niche": "啃除老草并给幼芽腾出生长地"},
	"monster_008": {"origin": "森林最高处汇聚的百道长风", "habitat": "天树、峭壁与云巢", "niche": "统领夜巡鸟群监测整片林海"},
	"monster_009": {"origin": "花粉落入羊毛结出的香软芽", "habitat": "花坡、蜂田与草溪", "niche": "驮送花粉让远隔花丛彼此授粉"},
	"monster_010": {"origin": "雨后草甸膨起的厚实绒云", "habitat": "湿草甸、石圈与谷地", "niche": "踩实松土并为小兽留下暖绒毛"},
	"monster_011": {"origin": "瀑布水雾滋养的花苞", "habitat": "瀑潭、湿壁与浅溪石", "niche": "吸附水尘并用花瓣滤净细小砂砾"},
	"monster_012": {"origin": "潮池气泡裹住的水声", "habitat": "浅滩、喷泉与石盆边", "niche": "喷水冲开淤泥并替小鱼拓宽水道"},
	"monster_013": {"origin": "大潮回声凝成的喷口", "habitat": "海蚀洞、瀑口与深潭", "niche": "调节急流并把缺氧深水翻到水面"},
	"monster_014": {"origin": "矿脉震动抖落的细碎灵砂", "habitat": "矿洞、碎岩与根穴边缘", "niche": "搬走松石并替深根植物打通土层"},
	"monster_015": {"origin": "老矿灯照暖的坚韧岩尘团块", "habitat": "旧矿道、岩仓与石桥下", "niche": "辨认矿层并封堵容易坍塌的裂口"},
	"monster_016": {"origin": "整座矿山回响聚成的厚重岩核", "habitat": "主矿厅、石脊与地下河岸", "niche": "指挥鼠群整理矿砂并支撑空洞岩壁"},
	"monster_017": {"origin": "林中第一声叹息留下的阴影", "habitat": "背光树根、冷泉与空树洞", "niche": "收集枯枝败叶并藏起刺鼻菌团"},
	"monster_018": {"origin": "连绵阴雨压沉的灰暗苔绒", "habitat": "雨林洼地、朽木与暗溪旁", "niche": "吞食腐果并限制酸性霉菌向外蔓延"},
	"monster_019": {"origin": "百年愁云积成的深黑情绪核", "habitat": "幽谷、废巢与月影沼泽间", "niche": "吸纳族群焦躁并驱赶破坏巢穴的兽群"},
	"monster_020": {"origin": "迷途脚印绕成的嫩绿毛线团", "habitat": "岔路草坡、雾谷与矮林", "niche": "踏出小径并把草籽带到偏僻处"},
	"monster_021": {"origin": "反复绕路沾满的枝叶与晨露", "habitat": "环形林道、苔坡与旧桥", "niche": "沿错误路线传播蕨类的孢子"},
	"monster_022": {"origin": "迷路传闻汇成的青色路团", "habitat": "密林深处、迷谷与断径", "niche": "带领兽群发现偏僻的新草场"},
	"monster_023": {"origin": "云底滑落的圆润雨珠", "habitat": "叶尖、浅塘与檐沟下", "niche": "湿润幼苗并替昆虫补充微小饮水点"},
	"monster_024": {"origin": "连日细雨汇成的水团", "habitat": "雨沟、池畔与荷叶间", "niche": "搬运雨水并填满林间干涸的小水洼"},
	"monster_025": {"origin": "暴雨云心滚动的水核", "habitat": "洪谷、云瀑与蓄水湖畔", "niche": "分散骤雨并延缓山洪冲入下游聚落"},
	"monster_026": {"origin": "第一道海雷遗落的细小电弧", "habitat": "礁顶、湿木与铜砂滩一带", "niche": "吞纳浮电并替海鸟清理带电羽毛"},
	"monster_027": {"origin": "两片雷云碰出的连续电鸣", "habitat": "雷岛、铁树林与高塔残垣边", "niche": "串联分散电荷并引导雷流避开巢穴"},
	"monster_028": {"origin": "南海雷暴压缩的紫白电核", "habitat": "风暴眼、磁石峰与黑云下方", "niche": "储存过量闪电并在晴日缓慢释放"},
	"monster_029": {"origin": "拳印形菌褶吸收的草木精气", "habitat": "腐木、练武坡与湿苔", "niche": "击碎硬壳果并让种仁落入软土"},
	"monster_030": {"origin": "千次落拳震醒的古老菌根", "habitat": "巨木桩、石台与菌林", "niche": "用拳风清除倒木替菌打开光隙"},
	"monster_031": {"origin": "洞穴回声裹住的叛逆音浪", "habitat": "风洞、石梁与空树干", "niche": "以低鸣驱散侵巢虫群并松落熟果"},
	"monster_032": {"origin": "逆风尖啸打磨的暗色翼膜", "habitat": "峭壁、废塔与逆风口", "niche": "巡查险峭风道并警告靠近的飞兽"},
	"monster_033": {"origin": "月夜节拍震出的彩色声纹", "habitat": "回音谷、空台与风林", "niche": "用节奏协调夜行族群错峰寻找食物"},
	"monster_034": {"origin": "遗迹灯火照醒的一株金色嫩芽", "habitat": "路碑、石阶与向阳废墟", "niche": "入夜持续发光并替迁徙小兽标出安全岔路"},
	"monster_035": {"origin": "千万旅人谢意汇入的明亮花芯", "habitat": "古道口、灯塔与花圃边", "niche": "接力照亮长路并引导夜花依次开放"},
	"monster_036": {"origin": "清晨辉光梳过的一束柔软鬃毛", "habitat": "镜湖、花台与阳光廊下", "niche": "梳落亮粉替暗处植物补充温和光照"},
	"monster_037": {"origin": "彩晶折射出的第一道绚丽光带", "habitat": "晶廊、舞台与彩花田间", "niche": "变换反光吸引远方传粉虫前来花田"},
	"monster_038": {"origin": "百面古镜共同映出的纯净光影", "habitat": "镜塔、辉晶洞与白石庭中", "niche": "校准散乱光束并压制灼伤幼芽的强光"},
	"monster_039": {"origin": "月色沉入暗河唤醒的幽蓝鱼影", "habitat": "暗河、深潭与沉木洞附近", "niche": "吞食水底腐屑并替洞鱼引开捕食者"},
	"monster_040": {"origin": "枯木年轮藏住的一点微弱心跳", "habitat": "朽木腹、根窟与阴湿林下", "niche": "分解软木并让甲虫能进入坚硬树芯"},
	"monster_041": {"origin": "古林倾倒后留下的木灵回声", "habitat": "倒木谷、黑林与腐殖层中间", "niche": "搬动枯干搭成菌床并保存林地湿气"},
	"monster_042": {"origin": "山坡滚石裹紧的一枚坚硬土核", "habitat": "砾坡、洞口与干河床一带", "niche": "滚动压实松坡并撞碎阻水的小石堆"},
	"monster_043": {"origin": "岩缝荆棘包裹的尖锐矿物灵核", "habitat": "刺岩滩、灌丛与峡谷石隙间", "niche": "翻松结块矿土并阻挡兽群踩踏幼苗"},
	"monster_044": {"origin": "风化石刺排列出的古老守卫图腾", "habitat": "石门、险坡与高地岩圈周围", "niche": "守护矿脉入口并给穴居小兽留下通道"},
	"monster_045": {"origin": "月下发酵果香引来的紫色蝎影", "habitat": "果窖、暗坡与枯木酒潭边缘", "niche": "清理过熟落果并抑制醉果霉菌滋生扩散"},
	"monster_046": {"origin": "百年果酿沉淀出的琥珀色尾钩", "habitat": "古酒窖、葡萄谷与幽暗石仓中", "niche": "看守发酵果堆并驱逐偷食后伤害果树的兽"},
	"monster_047": {"origin": "溪谷小石互相碰撞时苏醒的岩灵", "habitat": "卵石滩、山沟与浅洞口边缘", "niche": "滚开淤塞碎石并替溪水恢复通路"},
	"monster_048": {"origin": "山洪磨圆的巨岩积蓄出的地脉心跳", "habitat": "巨砾谷、河弯与山脚岩棚", "niche": "稳住河岸巨石并阻止急流掏空坡脚"},
	"monster_049": {"origin": "沙丘嫩芽包住的一枚蜥蜴卵", "habitat": "绿洲边、沙草与石荫", "niche": "捕食啃根小虫并保护沙生幼苗"},
	"monster_050": {"origin": "绿洲藤影驯服的蜥蜴灵气", "habitat": "棕榈根、绿岩与泉沟", "niche": "巡视水岸并把甲虫赶离嫩叶"},
	"monster_051": {"origin": "海风卷起细沙塑成的轻盈狐影", "habitat": "海丘、沙脊与风蚀洞", "niche": "踏平尖锐沙纹并替幼兽寻找背风地"},
	"monster_052": {"origin": "暮色潜入沙暴留下的幽暗狐影", "habitat": "黑沙谷、月丘与废井之间", "niche": "夜巡绿洲并驱赶偷食水草的沙虫群"},
	"monster_053": {"origin": "远航信封沾染的潮水", "habitat": "邮船、河港与潮汐驿站", "niche": "驮送种子与消息并巡查沿途水源变化"},
	"monster_054": {"origin": "破浪船首飞散的水沫", "habitat": "外海礁、急湾与风浪航道", "niche": "顶开漂浮杂物并为幼龟开辟回游路线"},
	"monster_055": {"origin": "暴雨航路激起的蓝色浪痕", "habitat": "雷雨海、远洋与云下航线边", "niche": "会在风暴前传递讯号引导船群避险"},
	"monster_056": {"origin": "海草呼吸吐出的气泡", "habitat": "藻床、浅湾与珊瑚缝里", "niche": "携带氧气进入密藻并托起沉底鱼卵"},
	"monster_057": {"origin": "潮池爆开的清脆泡声", "habitat": "石盆、浪沟与贝壳堆边", "niche": "啄开堵塞贝壳并放出困住的小虾群"},
	"monster_058": {"origin": "晨光沉入清泉凝成的亮晶水珠", "habitat": "水晶泉、白沙与日照潭边", "niche": "折光温暖浅水并抑制怕光水霉生长"},
	"monster_059": {"origin": "宝石潮汐堆起的耀眼辉光核心", "habitat": "晶洞、宝滩与光泉交界处", "niche": "收拢碎晶避免鱼群误食并照亮深水通道"},
	"monster_060": {"origin": "辉晶倒影跃出水面的敏捷豹影", "habitat": "晶瀑、亮岩与镜湖浅滩间", "niche": "驱赶啃食晶藻的鱼群并清理浑浊水面"},
	"monster_061": {"origin": "整条晶河折射出的斑斓豹形灵光", "habitat": "大晶瀑、光谷与透明岩桥下", "niche": "巡守晶河源头并把碎裂晶片搬离水道"},
	"monster_062": {"origin": "海螺深处回荡的噜声", "habitat": "海草床、螺礁与暖流湾", "niche": "翻动海沙并给幼贝清出附着的硬面"},
	"monster_063": {"origin": "深海低鸣凝聚的回声", "habitat": "深海沟、巨螺与冷泉口旁", "niche": "搅动沉水补充氧气并护送鱼群越过暗沟"},
	"monster_064": {"origin": "椰壳接住雨水萌发的绿芽", "habitat": "椰林、沙滩与淡水洼边", "niche": "搬运落果并把椰种推到潮线外"},
	"monster_065": {"origin": "季风吹落的成熟椰果灵气", "habitat": "高椰林、岸坡与林溪口", "niche": "撞开厚壳供兽取食并散播果核"},
	"monster_066": {"origin": "丰收季椰香聚成的沉稳果灵", "habitat": "老椰林、沃岸与村落边", "niche": "储水并用宽叶替幼苗挡住盐雾"},
	"monster_067": {"origin": "急流水纹勾出的豹影", "habitat": "溪峡、瀑道与滑石岸边", "niche": "追赶病弱鱼群并维持溪流猎物健康"},
	"monster_068": {"origin": "百道溪流汇成的蓝纹", "habitat": "大瀑、河峡与潮湿石林", "niche": "巡视支流并驱散堵住鱼道的漂木堆积"},
	"monster_069": {"origin": "长河奔海凝出的水影", "habitat": "长河口、海瀑与深峡水道", "niche": "穿梭全河传递汛情并引领鱼群及时迁徙"},
	"monster_070": {"origin": "浮冰裂隙孵出的稚鸣", "habitat": "浮冰、雪湾与冷水岸边", "niche": "啄开薄冰气孔并给水下生物补充空气"},
	"monster_071": {"origin": "冰光养成的企鹅灵气", "habitat": "冰岛、寒湾与雪坡脚下", "niche": "轮流护卵并踏出连接海岸与巢区的雪路"},
	"monster_072": {"origin": "冰川回声拥立的王冠", "habitat": "王冰台、极海与冰川门前", "niche": "统领企鹅群疏散浮冰并守护整片繁殖地"},
	"monster_073": {"origin": "潮沙包住的柔软贝珠", "habitat": "泥滩、浅礁与贝草丛里", "niche": "过滤浮游碎屑并给幼贝清洁附着水面"},
	"monster_074": {"origin": "双层贝壳护住的潮声", "habitat": "贝礁、潮沟与海草床间", "niche": "聚拢散落贝苗并用壳挡住强浪冲刷"},
	"monster_075": {"origin": "古贝礁孕育的潮汐灵气", "habitat": "贝城、深湾与蓝藻原中心", "niche": "修补破损贝礁并为众多幼鱼提供藏身孔"},
	"monster_076": {"origin": "雪落泉眼化成的兽影", "habitat": "雪泉、冰林与白石溪岸", "niche": "舔净积雪杂质并寻找未冻结的饮水口"},
	"monster_077": {"origin": "九股雪风交织出的尾羽", "habitat": "雪峰、冰桥与寒松林间", "niche": "用尾巴扫开雪层并露出越冬植物嫩芽"},
	"monster_078": {"origin": "月色凝成的九尾灵光", "habitat": "晶冰洞、月湖与极光坡边", "niche": "折射微光引导雪夜迷途生物回到巢穴"},
	"monster_079": {"origin": "极光落地凝成的熊影", "habitat": "极光湖、雪丘与冰原边缘", "niche": "拨开积雪寻找冻果并与小兽分享食物"},
	"monster_080": {"origin": "五色冰光拥抱的绒毛", "habitat": "彩冰谷、光雪与暖泉旁边", "niche": "用体温维持小片融水供寒地鸟兽饮用"},
	"monster_081": {"origin": "迷航夜空落下的第一粒指路星尘", "habitat": "观星台、高原与夜光花田中", "niche": "依星位闪烁并替夜行族群校正迁徙方向"},
	"monster_082": {"origin": "黎明前最亮星光凝成的引航灵体", "habitat": "东峰、晨晶谷与云海上缘处", "niche": "提前唤醒晨花并通知昼行生物准备出巢"},
	"monster_083": {"origin": "穿越花海的彗尾洒落成萤火光群", "habitat": "星落原、夜林与高空花径间", "niche": "带领萤群传播夜花粉并记录季节星轨"},
	"monster_084": {"origin": "月影树洞积攒的香甜睡意", "habitat": "软苔窝、暗林与静谧洞穴中", "niche": "降低夜间喧闹并把落叶拢成保温巢材"},
	"monster_085": {"origin": "漫长雨季酝酿的浓厚沉静困意", "habitat": "深树洞、雨林与背光山坳里", "niche": "以呼噜震落熟果并给小兽留下越冬储粮"},
	"monster_086": {"origin": "整座冬眠谷汇聚的梦境阴影", "habitat": "眠石谷、古洞与终年暗林深处", "niche": "守住安静冬眠地并驱离频繁扰巢的兽群"},
	"monster_087": {"origin": "地脉暖意孵化的一枚粗糙龙卵碎片", "habitat": "土穴、岩沟与暖石坡附近", "niche": "掘开板结地层并给幼苗留下伸展空隙"},
	"monster_088": {"origin": "群山震鸣唤醒的坚实成年龙骨", "habitat": "山腹、石林与地下熔洞外围", "niche": "开凿新洞道并引导地下水避开岩层"},
	"monster_089": {"origin": "大陆岩脊共同铸成的古老领主龙魂", "habitat": "主峰、龙窟与巨型断层深处", "niche": "镇住断层并率领地龙修复坍塌洞网"},
	"monster_090": {"origin": "夜风吻过花苞留下的梦境", "habitat": "月园、林窗与夜露花径", "niche": "释放香气吸引传粉的夜蛾群"},
	"monster_091": {"origin": "满楼花影交叠后凝出的花灵", "habitat": "藤楼、花墙与庭院深处", "niche": "撑起花架并给小鸟提供筑巢处"},
	"monster_092": {"origin": "凤尾花粉随晨风汇聚的仙影", "habitat": "凤花谷、溪畔与彩叶林", "niche": "引导蜂蝶采粉避免花丛受损"},
	"monster_093": {"origin": "篝火第一颗火星跳进幼犬脚印", "habitat": "暖岩、营火与红砂路旁", "niche": "巡守营地并用余温帮助耐热种子萌芽"},
	"monster_094": {"origin": "熔岩河边奔跑凝成的赤红犬魂", "habitat": "熔岩岸、火洞与黑石坡", "niche": "嗅出地热裂口并提前警告族群撤离"},
	"monster_095": {"origin": "温热火山砂孵出的幼蟹火核", "habitat": "热沙滩、岩池与火山脚", "niche": "翻动热砂并清理被烤焦的海藻残片"},
	"monster_096": {"origin": "岩浆潮反复锻硬的蟹甲灵气", "habitat": "熔岩滩、热泉与玄武岩洞", "niche": "搬走滚烫落石并给生物筑起隔热墙"},
	"monster_097": {"origin": "红砂旱季积压的一股暴躁热气", "habitat": "红土坡、枯林与热泥坑", "niche": "拱开硬土寻找块根并留下蓄雨浅坑"},
	"monster_098": {"origin": "火山震响激怒的猛烈野猪魂魄", "habitat": "熔岩林、焦土与山麓沟", "niche": "撞倒焦枯树干并阻断地表火线"},
	"monster_099": {"origin": "辛香在热锅里旋转出的火灵", "habitat": "温泉灶、香草坡与营帐", "niche": "蒸煮有毒块根并让其他族群安全取食"},
	"monster_100": {"origin": "火山石锅熬出的浓烈赤色汤魂", "habitat": "火口台、岩灶与沸泉边", "niche": "吸走沸泉过热能量并维持水温稳定"},
	"monster_101": {"origin": "暖流穿过岩浆礁唤醒的鱼影", "habitat": "热海沟、岩礁与温泉河口", "niche": "啄食焦藻并保持热水通道持续畅通"},
	"monster_102": {"origin": "火山泉中孵化的一颗赤红鱼卵", "habitat": "暖泉池、浅礁与火山溪边", "niche": "吞食细小热藻并为大鱼探测安全水温"},
	"monster_103": {"origin": "两股熔潮碰撞锻成的斗鱼火魂", "habitat": "熔海湾、赤礁与火瀑下方", "niche": "争夺水道后守卫鱼卵免遭热流冲散"},
	"monster_boss_001": {"origin": "风草原共同呼吸凝成的巨兽", "habitat": "古花原、巨树与圣泉", "niche": "播撒海量种子并唤醒沉睡根网"},
	"monster_boss_002": {"origin": "古战场刀盾埋入山岩后生出的守灵", "habitat": "石垒、关隘与废弃堡垒内", "niche": "阻挡落石并替山路旅群守住通行口"},
	"monster_boss_003": {"origin": "圣殿晨光汇入杯中凝成的白瑞兽", "habitat": "辉光殿、云阶与水晶庭院", "niche": "收纳烈光再化为柔辉照料大片夜开花田"},
	"monster_boss_004": {"origin": "群山崩裂后最完整的一块地脉岩心", "habitat": "断山谷、巨岩阵与地底石宫", "niche": "支撑山体并重排堵塞地下河的巨石"},
	"monster_boss_005": {"origin": "海沟潮压塑成的蓝色影", "habitat": "渊海沟、暗流与沉船墓场", "niche": "驱赶过密猎食群并搅动深海养分上升"},
	"monster_boss_006": {"origin": "风雪拥立的银白狐王", "habitat": "冰冠峰、雪原与极光洞穴", "niche": "巡视冰原并带领雪狐寻找季节性融水地"},
	"monster_boss_007": {"origin": "迷失影子在裂隙深处交叠成形", "habitat": "虚暗裂谷、遗迹与无光洞窟深处", "niche": "吞没失控暗能并把危险波动困在封闭区域"},
	"monster_boss_008": {"origin": "火山林燃烧后重聚的赤红巨灵", "habitat": "火口、焦木林与熔岩台地", "niche": "吞下野火缓慢释放灰烬肥沃新生土壤"},
}


static func get_ecology(monster: Dictionary) -> Dictionary:
	var monster_id := str(monster.get("id", ""))
	var core: Dictionary = (CORES.get(monster_id, {}) as Dictionary).duplicate(true)
	if core.is_empty():
		return {}
	var name := str(monster.get("name", monster_id))
	return {
		"id": monster_id,
		"name": TranslationServer.translate("%s生态札记") % name,
		"origin": str(core.get("origin", "")),
		"habitat": str(core.get("habitat", "")),
		"niche": str(core.get("niche", "")),
		"adventurerTip": TranslationServer.translate("与%s同行时，留意它会%s；给它保留观察和休息的空间。") % [TranslationServer.translate(name), TranslationServer.translate(str(core.get("niche", "参与当地生态")))],
	}


static func validate_catalog(monsters: Array) -> Dictionary:
	var missing: Array[String] = []
	var signatures := {}
	var duplicates: Array[String] = []
	for monster: Dictionary in monsters:
		var monster_id := str(monster.get("id", ""))
		var core: Dictionary = CORES.get(monster_id, {})
		if core.is_empty():
			missing.append(monster_id)
			continue
		var signature := "%s|%s|%s" % [core.get("origin", ""), core.get("habitat", ""), core.get("niche", "")]
		if signatures.has(signature):
			duplicates.append("%s=%s" % [monster_id, signatures[signature]])
		else:
			signatures[signature] = monster_id
	return {"ok": missing.is_empty() and duplicates.is_empty(), "missing": missing, "duplicates": duplicates, "count": CORES.size()}
