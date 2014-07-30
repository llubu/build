#ifndef __TESTB_H__
#define __TESTB_H__

#ifdef TESTB_EXPORTS
	#ifdef _MSC_VER
		#define TESTB_API	__declspec(dllexport)
	#else /* Linux */
		#define TESTB_API	__attribute__ ((visibility ("default")))
	#endif /* _MSC_VER */
#else
	#ifdef _MSC_VER
		#define TESTB_API	__declspec(dllimport)
	#else /* Linux */
		#define TESTB_API
	#endif /* _MSC_VER */
#endif /* TESTB_EXPORTS */

void TESTB_API PrintHelloWorldDynamic(void);

#endif /* __TESTB_H__ */
